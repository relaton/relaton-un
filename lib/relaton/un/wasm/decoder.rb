# frozen_string_literal: true

module Relaton
  module Un
    module Wasm
      # Binary WebAssembly decoder. Handles the subset of WASM MVP plus the
      # sign-extension proposal that the shipped wasm_v_bg.wasm uses. No
      # floats, no SIMD, no bulk-memory, no reference types beyond funcref.
      class Decoder
        MAGIC = "\x00asm".b
        VERSION = "\x01\x00\x00\x00".b

        VALTYPE_I32 = 0x7F
        VALTYPE_I64 = 0x7E
        VALTYPE_F32 = 0x7D
        VALTYPE_F64 = 0x7C

        def initialize(bytes)
          @bytes = bytes.b
          @pos = 0
        end

        def decode
          header!
          mod = Module.new
          until eof?
            id = read_byte
            size = read_u32
            section_end = @pos + size
            decode_section(mod, id, section_end)
            @pos = section_end
          end
          mod
        end

        private

        def header!
          magic = take(4)
          raise DecodeError, "bad magic: #{magic.inspect}" unless magic == MAGIC

          version = take(4)
          raise DecodeError, "bad version: #{version.inspect}" unless version == VERSION
        end

        def decode_section(mod, id, section_end)
          case id
          when 0  then skip_to(section_end) # custom
          when 1  then decode_types(mod)
          when 2  then decode_imports(mod)
          when 3  then decode_functions(mod)
          when 4  then decode_tables(mod)
          when 5  then decode_memories(mod)
          when 6  then decode_globals(mod)
          when 7  then decode_exports(mod)
          when 8  then mod.instance_variable_set(:@start, read_u32)
          when 9  then decode_elements(mod)
          when 10 then decode_code(mod)
          when 11 then decode_data(mod)
          else raise DecodeError, "unknown section id #{id}"
          end
        end

        def decode_types(mod)
          read_vec do
            tag = read_byte
            raise DecodeError, "bad functype tag #{tag}" unless tag == 0x60

            params = read_vec { read_byte }
            results = read_vec { read_byte }
            mod.types << FuncType.new(params, results)
          end
        end

        def decode_imports(mod)
          read_vec do
            mod_name = read_name
            field = read_name
            kind_byte = read_byte
            kind, desc = case kind_byte
                        when 0x00 then [:func, read_u32]
                        when 0x01 then [:table, decode_tabletype]
                        when 0x02 then [:memory, decode_memtype]
                        when 0x03 then [:global, [read_byte, read_byte == 1]]
                        else raise DecodeError, "bad import kind #{kind_byte}"
                        end
            mod.imports << Import.new(mod_name, field, kind, desc)
            mod.function_type_indices << desc if kind == :func
          end
        end

        def decode_functions(mod)
          read_vec do
            mod.function_type_indices << read_u32
          end
        end

        def decode_tables(mod)
          read_vec do
            mod.tables << decode_tabletype
          end
        end

        def decode_memories(mod)
          read_vec do
            mod.memories << decode_memtype
          end
        end

        def decode_globals(mod)
          read_vec do
            valtype = read_byte
            mutable = read_byte == 1
            init_expr = decode_const_expr
            mod.globals << Global.new(valtype, mutable, init_expr)
          end
        end

        def decode_exports(mod)
          read_vec do
            name = read_name
            kind_byte = read_byte
            kind = case kind_byte
                  when 0x00 then :func
                  when 0x01 then :table
                  when 0x02 then :memory
                  when 0x03 then :global
                  else raise DecodeError, "bad export kind #{kind_byte}"
                  end
            mod.exports << Export.new(name, kind, read_u32)
          end
        end

        def decode_elements(mod)
          read_vec do
            flags = read_u32
            # MVP form: flags == 0 means active, table 0, offset, funcref vec.
            raise DecodeError, "unsupported element segment flags #{flags}" unless flags.zero?

            offset_expr = decode_const_expr
            funcs = read_vec { read_u32 }
            mod.elements << Element.new(0, offset_expr, funcs)
          end
        end

        def decode_code(mod)
          read_vec do
            size = read_u32
            body_end = @pos + size
            local_groups = read_vec { [read_u32, read_byte] } # [count, valtype]
            locals = local_groups.flat_map { |count, vt| Array.new(count, vt) }
            body = decode_instructions(body_end)
            mod.code << Code.new(locals, body)
            @pos = body_end
          end
        end

        def decode_data(mod)
          read_vec do
            flags = read_u32
            mem_idx = 0
            offset_expr = nil
            case flags
            when 0
              offset_expr = decode_const_expr
            when 1
              # passive — not used here
            when 2
              mem_idx = read_u32
              offset_expr = decode_const_expr
            else
              raise DecodeError, "bad data flags #{flags}"
            end
            bytes = take(read_u32)
            mod.data << Data.new(mem_idx, offset_expr, bytes)
          end
        end

        def decode_tabletype
          elem_type = read_byte
          decode_limits.then { |init, max| TableType.new(elem_type, init, max) }
        end

        def decode_memtype
          decode_limits.then { |init, max| MemoryType.new(init, max) }
        end

        def decode_limits
          flag = read_byte
          init = read_u32
          max = flag == 1 ? read_u32 : nil
          [init, max]
        end

        # A constant init expression: a single instruction followed by `end`.
        # For our module it'll only be i32.const / i64.const / global.get.
        def decode_const_expr
          op = read_byte
          val = case op
               when 0x41 then [:i32_const, read_s32]
               when 0x42 then [:i64_const, read_s64]
               when 0x23 then [:global_get, read_u32]
               else raise DecodeError, "unsupported const expr op 0x#{op.to_s(16)}"
               end
          end_op = read_byte
          raise DecodeError, "const expr not terminated with end (got 0x#{end_op.to_s(16)})" unless end_op == 0x0B

          val
        end

        # Decode the instruction stream of a function body up to its final
        # `end`. Returns a flat array of [op_sym, *operands]. Block-introducing
        # ops are post-processed to carry `end_pc` (and `else_pc` for `if`)
        # so the interpreter can jump without scanning at runtime.
        def decode_instructions(body_end)
          instrs = []
          stack = [] # of [kind_sym, instr_index]

          until @pos >= body_end
            op = read_byte
            pc = instrs.size
            case op
            when 0x00 then instrs << [:unreachable]
            when 0x01 then instrs << [:nop]
            when 0x02
              bt = decode_blocktype
              instrs << [:block, bt, nil] # end_pc filled in below
              stack << [:block, pc]
            when 0x03
              bt = decode_blocktype
              instrs << [:loop, bt, nil]
              stack << [:loop, pc]
            when 0x04
              bt = decode_blocktype
              instrs << [:if, bt, nil, nil] # else_pc, end_pc
              stack << [:if, pc]
            when 0x05
              if_kind, if_pc = stack.last
              raise DecodeError, "else without matching if" unless if_kind == :if

              instrs[if_pc][2] = pc # else_pc points at the `else` instruction
              instrs << [:else, nil]
            when 0x0B
              instrs << [:end]
              if stack.any?
                kind, intro_pc = stack.pop
                case kind
                when :block, :loop then instrs[intro_pc][2] = pc
                when :if
                  instrs[intro_pc][3] = pc # end_pc
                  instrs[intro_pc][2] ||= pc # else_pc defaults to end_pc
                  # if there was an `else`, fix it up
                  else_pc = instrs[intro_pc][2]
                  instrs[else_pc][1] = pc if else_pc < pc && instrs[else_pc][0] == :else
                end
              end
            when 0x0C then instrs << [:br, read_u32]
            when 0x0D then instrs << [:br_if, read_u32]
            when 0x0E
              labels = read_vec { read_u32 }
              default = read_u32
              instrs << [:br_table, labels, default]
            when 0x0F then instrs << [:return_]
            when 0x10 then instrs << [:call, read_u32]
            when 0x11
              type_idx = read_u32
              table_idx = read_u32
              instrs << [:call_indirect, type_idx, table_idx]
            when 0x1A then instrs << [:drop]
            when 0x1B then instrs << [:select]
            when 0x20 then instrs << [:local_get, read_u32]
            when 0x21 then instrs << [:local_set, read_u32]
            when 0x22 then instrs << [:local_tee, read_u32]
            when 0x23 then instrs << [:global_get, read_u32]
            when 0x24 then instrs << [:global_set, read_u32]
            when 0x28..0x3E
              align = read_u32
              offset = read_u32
              instrs << [MEM_OPS[op], align, offset]
            when 0x3F
              read_byte # reserved
              instrs << [:memory_size]
            when 0x40
              read_byte # reserved
              instrs << [:memory_grow]
            when 0x41 then instrs << [:i32_const, read_s32]
            when 0x42 then instrs << [:i64_const, read_s64]
            when 0x45..0x8A then instrs << [NUM_OPS.fetch(op)]
            when 0xA7 then instrs << [:i32_wrap_i64]
            when 0xAC then instrs << [:i64_extend_i32_s]
            when 0xAD then instrs << [:i64_extend_i32_u]
            when 0xC0 then instrs << [:i32_extend8_s]
            when 0xC1 then instrs << [:i32_extend16_s]
            when 0xC2 then instrs << [:i64_extend8_s]
            when 0xC3 then instrs << [:i64_extend16_s]
            when 0xC4 then instrs << [:i64_extend32_s]
            else
              raise DecodeError, "unsupported opcode 0x#{op.to_s(16)} at byte #{@pos - 1}"
            end
          end
          instrs
        end

        # Block type: 0x40 = empty, single valtype byte, or signed LEB128 type
        # index. Returns one of [:empty] / [:value, valtype] / [:typeidx, idx].
        def decode_blocktype
          b = peek_byte
          if b == 0x40
            read_byte
            [:empty]
          elsif [VALTYPE_I32, VALTYPE_I64, VALTYPE_F32, VALTYPE_F64].include?(b)
            [:value, read_byte]
          else
            [:typeidx, read_s33]
          end
        end

        MEM_OPS = {
          0x28 => :i32_load,    0x29 => :i64_load,
          0x2C => :i32_load8_s, 0x2D => :i32_load8_u,
          0x2E => :i32_load16_s, 0x2F => :i32_load16_u,
          0x30 => :i64_load8_s, 0x31 => :i64_load8_u,
          0x32 => :i64_load16_s, 0x33 => :i64_load16_u,
          0x34 => :i64_load32_s, 0x35 => :i64_load32_u,
          0x36 => :i32_store,   0x37 => :i64_store,
          0x3A => :i32_store8,  0x3B => :i32_store16,
          0x3C => :i64_store8,  0x3D => :i64_store16,
          0x3E => :i64_store32
        }.freeze

        NUM_OPS = {
          0x45 => :i32_eqz, 0x46 => :i32_eq, 0x47 => :i32_ne,
          0x48 => :i32_lt_s, 0x49 => :i32_lt_u, 0x4A => :i32_gt_s, 0x4B => :i32_gt_u,
          0x4C => :i32_le_s, 0x4D => :i32_le_u, 0x4E => :i32_ge_s, 0x4F => :i32_ge_u,
          0x50 => :i64_eqz, 0x51 => :i64_eq, 0x52 => :i64_ne,
          0x53 => :i64_lt_s, 0x54 => :i64_lt_u, 0x55 => :i64_gt_s, 0x56 => :i64_gt_u,
          0x57 => :i64_le_s, 0x58 => :i64_le_u, 0x59 => :i64_ge_s, 0x5A => :i64_ge_u,
          0x67 => :i32_clz, 0x68 => :i32_ctz, 0x69 => :i32_popcnt,
          0x6A => :i32_add, 0x6B => :i32_sub, 0x6C => :i32_mul,
          0x6D => :i32_div_s, 0x6E => :i32_div_u, 0x6F => :i32_rem_s, 0x70 => :i32_rem_u,
          0x71 => :i32_and, 0x72 => :i32_or, 0x73 => :i32_xor,
          0x74 => :i32_shl, 0x75 => :i32_shr_s, 0x76 => :i32_shr_u,
          0x77 => :i32_rotl, 0x78 => :i32_rotr,
          0x79 => :i64_clz, 0x7A => :i64_ctz, 0x7B => :i64_popcnt,
          0x7C => :i64_add, 0x7D => :i64_sub, 0x7E => :i64_mul,
          0x7F => :i64_div_s, 0x80 => :i64_div_u, 0x81 => :i64_rem_s, 0x82 => :i64_rem_u,
          0x83 => :i64_and, 0x84 => :i64_or, 0x85 => :i64_xor,
          0x86 => :i64_shl, 0x87 => :i64_shr_s, 0x88 => :i64_shr_u,
          0x89 => :i64_rotl, 0x8A => :i64_rotr
        }.freeze

        # ---- low-level reading -----------------------------------------------

        def eof?
          @pos >= @bytes.bytesize
        end

        def read_byte
          b = @bytes.getbyte(@pos)
          raise DecodeError, "unexpected eof" unless b

          @pos += 1
          b
        end

        def peek_byte
          @bytes.getbyte(@pos) or raise(DecodeError, "unexpected eof")
        end

        def take(n)
          s = @bytes.byteslice(@pos, n)
          raise DecodeError, "unexpected eof (wanted #{n} bytes)" unless s && s.bytesize == n

          @pos += n
          s
        end

        def skip_to(end_pos)
          @pos = end_pos
        end

        def read_u32
          result = 0
          shift = 0
          loop do
            b = read_byte
            result |= (b & 0x7F) << shift
            break if (b & 0x80).zero?

            shift += 7
            raise DecodeError, "u32 overflow" if shift > 35
          end
          result
        end

        def read_s32
          read_signed(32)
        end

        def read_s33
          read_signed(33)
        end

        def read_s64
          read_signed(64)
        end

        def read_signed(bits)
          result = 0
          shift = 0
          loop do
            b = read_byte
            result |= (b & 0x7F) << shift
            shift += 7
            if (b & 0x80).zero?
              result -= (1 << shift) if shift < bits && (b & 0x40).positive?
              return result
            end
            raise DecodeError, "signed overflow" if shift > bits + 7
          end
        end

        def read_name
          take(read_u32).force_encoding(Encoding::UTF_8)
        end

        def read_vec
          count = read_u32
          Array.new(count) { yield }
        end
      end
    end
  end
end
