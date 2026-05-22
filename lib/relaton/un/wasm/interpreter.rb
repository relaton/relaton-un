# frozen_string_literal: true

module Relaton
  module Un
    module Wasm
      I32_MASK = 0xFFFF_FFFF
      I64_MASK = 0xFFFF_FFFF_FFFF_FFFF
      I32_SIGN = 0x8000_0000
      I64_SIGN = 0x8000_0000_0000_0000
      I32_RANGE = 0x1_0000_0000
      I64_RANGE = 0x1_0000_0000_0000_0000

      # Convert unsigned i32/i64 to signed.
      def self.to_s32(x); x >= I32_SIGN ? x - I32_RANGE : x; end
      def self.to_s64(x); x >= I64_SIGN ? x - I64_RANGE : x; end

      # A wasm function — module-defined or imported.
      FuncRef = Struct.new(:type, :kind, :code, :proc) do
        def imported?; kind == :import; end
      end

      # The `caller` object passed to imported procs. Mirrors the shape the
      # existing token_generator.rb expects: `caller.export("memory").to_memory`
      # and `caller.export("__wbindgen_malloc").to_func`.
      class Caller
        def initialize(instance)
          @instance = instance
        end

        def export(name)
          ExportRef.new(@instance, name)
        end
      end

      ExportRef = Struct.new(:instance, :name) do
        def to_memory; MemoryAdapter.new(instance.memory); end

        def to_func
          func_idx = instance.export_index(name, :func)
          ->(*args) { instance.invoke_by_index(func_idx, args) }
        end
      end

      # Thin shim presenting the wasmtime Memory API the existing import
      # bodies expect: #read(addr, len) returning bytes, #write(addr, bytes).
      MemoryAdapter = Struct.new(:memory) do
        def read(addr, len); memory.read(addr, len); end
        def write(addr, bytes); memory.write(addr, bytes); end
      end

      class Interpreter
        def initialize(instance)
          @instance = instance
        end

        def invoke(func_idx, args)
          func = @instance.funcs[func_idx]
          if func.imported?
            return func.proc.call(Caller.new(@instance), *args)
          end

          run_function(func, args)
        end

        private

        def run_function(func, args) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/PerceivedComplexity,Metrics/CyclomaticComplexity
          ftype = func.type
          # locals = function args + declared locals (zero-initialized)
          locals = Array.new(ftype.params.size + func.code.locals.size, 0)
          ftype.params.each_with_index { |_t, i| locals[i] = args[i] }

          body = func.code.body
          vstack = []
          # Each label: [target_pc, arity, value_stack_height_at_entry, is_loop]
          # Function-level implicit label: target_pc past end, arity = result arity.
          label_stack = [[body.size, ftype.results.size, 0, false]]
          pc = 0

          while pc < body.size
            instr = body[pc]
            op = instr[0]

            case op
            when :local_get
              vstack << locals[instr[1]]
              pc += 1
            when :i32_const, :i64_const
              vstack << instr[1]
              pc += 1
            when :i32_add
              b = vstack.pop; a = vstack.pop
              vstack << ((a + b) & I32_MASK)
              pc += 1
            when :i32_xor
              b = vstack.pop; a = vstack.pop
              vstack << ((a ^ b) & I32_MASK)
              pc += 1
            when :i32_and
              b = vstack.pop; a = vstack.pop
              vstack << ((a & b) & I32_MASK)
              pc += 1
            when :i32_or
              b = vstack.pop; a = vstack.pop
              vstack << ((a | b) & I32_MASK)
              pc += 1
            when :i32_sub
              b = vstack.pop; a = vstack.pop
              vstack << ((a - b) & I32_MASK)
              pc += 1
            when :i32_mul
              b = vstack.pop; a = vstack.pop
              vstack << ((a * b) & I32_MASK)
              pc += 1
            when :i32_shl
              b = vstack.pop; a = vstack.pop
              vstack << ((a << (b & 31)) & I32_MASK)
              pc += 1
            when :i32_shr_u
              b = vstack.pop; a = vstack.pop
              vstack << ((a & I32_MASK) >> (b & 31))
              pc += 1
            when :i32_shr_s
              b = vstack.pop; a = Wasm.to_s32(vstack.pop)
              shift = b & 31
              vstack << ((a >> shift) & I32_MASK)
              pc += 1
            when :i32_rotl
              b = vstack.pop; a = vstack.pop & I32_MASK
              n = b & 31
              vstack << (((a << n) | (a >> (32 - n))) & I32_MASK)
              pc += 1
            when :i32_rotr
              b = vstack.pop; a = vstack.pop & I32_MASK
              n = b & 31
              vstack << (((a >> n) | (a << (32 - n))) & I32_MASK)
              pc += 1
            when :i32_load
              addr = vstack.pop + instr[2]
              vstack << @instance.memory.load_u32(addr)
              pc += 1
            when :i32_store
              v = vstack.pop; addr = vstack.pop + instr[2]
              @instance.memory.store_u32(addr, v)
              pc += 1
            when :i32_load8_u
              addr = vstack.pop + instr[2]
              vstack << @instance.memory.load_u8(addr)
              pc += 1
            when :i32_load8_s
              addr = vstack.pop + instr[2]
              vstack << (@instance.memory.load_i8(addr) & I32_MASK)
              pc += 1
            when :i32_load16_u
              addr = vstack.pop + instr[2]
              vstack << @instance.memory.load_u16(addr)
              pc += 1
            when :i32_load16_s
              addr = vstack.pop + instr[2]
              vstack << (@instance.memory.load_i16(addr) & I32_MASK)
              pc += 1
            when :i32_store8
              v = vstack.pop; addr = vstack.pop + instr[2]
              @instance.memory.store_u8(addr, v)
              pc += 1
            when :i32_store16
              v = vstack.pop; addr = vstack.pop + instr[2]
              @instance.memory.store_u16(addr, v)
              pc += 1
            when :i64_load
              addr = vstack.pop + instr[2]
              vstack << @instance.memory.load_u64(addr)
              pc += 1
            when :i64_store
              v = vstack.pop; addr = vstack.pop + instr[2]
              @instance.memory.store_u64(addr, v)
              pc += 1
            when :i64_load8_u
              addr = vstack.pop + instr[2]
              vstack << @instance.memory.load_u8(addr)
              pc += 1
            when :i64_load8_s
              addr = vstack.pop + instr[2]
              vstack << (@instance.memory.load_i8(addr) & I64_MASK)
              pc += 1
            when :i64_load16_u
              addr = vstack.pop + instr[2]
              vstack << @instance.memory.load_u16(addr)
              pc += 1
            when :i64_load16_s
              addr = vstack.pop + instr[2]
              vstack << (@instance.memory.load_i16(addr) & I64_MASK)
              pc += 1
            when :i64_load32_u
              addr = vstack.pop + instr[2]
              vstack << @instance.memory.load_u32(addr)
              pc += 1
            when :i64_load32_s
              addr = vstack.pop + instr[2]
              vstack << (@instance.memory.load_i32(addr) & I64_MASK)
              pc += 1
            when :i64_store8
              v = vstack.pop; addr = vstack.pop + instr[2]
              @instance.memory.store_u8(addr, v)
              pc += 1
            when :i64_store16
              v = vstack.pop; addr = vstack.pop + instr[2]
              @instance.memory.store_u16(addr, v)
              pc += 1
            when :i64_store32
              v = vstack.pop; addr = vstack.pop + instr[2]
              @instance.memory.store_u32(addr, v)
              pc += 1
            when :br_if
              cond = vstack.pop
              if cond.zero?
                pc += 1
              else
                pc = do_branch(label_stack, vstack, instr[1])
                return finish(vstack, ftype) if label_stack.empty?
              end
            when :br
              pc = do_branch(label_stack, vstack, instr[1])
              return finish(vstack, ftype) if label_stack.empty?
            when :block
              # [:block, blocktype, end_pc]
              arity = block_result_arity(instr[1])
              label_stack << [instr[2] + 1, arity, vstack.size - block_param_arity(instr[1]), false]
              pc += 1
            when :loop
              # [:loop, blocktype, end_pc]; br to a loop re-executes the loop
              # op (which freshly pushes a label), so target_pc = the loop op
              # itself.
              arity = block_param_arity(instr[1])
              label_stack << [pc, arity, vstack.size - arity, true]
              pc += 1
            when :if
              # [:if, blocktype, else_pc, end_pc]
              cond = vstack.pop
              arity = block_result_arity(instr[1])
              label_stack << [instr[3] + 1, arity, vstack.size - block_param_arity(instr[1]), false]
              if cond.zero?
                else_pc = instr[2]
                end_pc = instr[3]
                pc = (else_pc == end_pc ? end_pc : else_pc + 1)
              else
                pc += 1
              end
            when :else
              # Reached at end of the then-branch: skip the else body to end+1.
              pc = instr[1] + 1
            when :end
              label_stack.pop
              return finish(vstack, ftype) if label_stack.empty?

              pc += 1
            when :local_set
              locals[instr[1]] = vstack.pop
              pc += 1
            when :local_tee
              locals[instr[1]] = vstack.last
              pc += 1
            when :global_get
              vstack << @instance.globals[instr[1]]
              pc += 1
            when :global_set
              @instance.globals[instr[1]] = vstack.pop
              pc += 1
            when :i32_eqz
              vstack << (vstack.pop.zero? ? 1 : 0)
              pc += 1
            when :i32_eq
              b = vstack.pop; a = vstack.pop
              vstack << (a == b ? 1 : 0)
              pc += 1
            when :i32_ne
              b = vstack.pop; a = vstack.pop
              vstack << (a == b ? 0 : 1)
              pc += 1
            when :i32_lt_u
              b = vstack.pop; a = vstack.pop
              vstack << (a < b ? 1 : 0)
              pc += 1
            when :i32_lt_s
              b = Wasm.to_s32(vstack.pop); a = Wasm.to_s32(vstack.pop)
              vstack << (a < b ? 1 : 0)
              pc += 1
            when :i32_gt_u
              b = vstack.pop; a = vstack.pop
              vstack << (a > b ? 1 : 0)
              pc += 1
            when :i32_gt_s
              b = Wasm.to_s32(vstack.pop); a = Wasm.to_s32(vstack.pop)
              vstack << (a > b ? 1 : 0)
              pc += 1
            when :i32_le_u
              b = vstack.pop; a = vstack.pop
              vstack << (a <= b ? 1 : 0)
              pc += 1
            when :i32_le_s
              b = Wasm.to_s32(vstack.pop); a = Wasm.to_s32(vstack.pop)
              vstack << (a <= b ? 1 : 0)
              pc += 1
            when :i32_ge_u
              b = vstack.pop; a = vstack.pop
              vstack << (a >= b ? 1 : 0)
              pc += 1
            when :i32_ge_s
              b = Wasm.to_s32(vstack.pop); a = Wasm.to_s32(vstack.pop)
              vstack << (a >= b ? 1 : 0)
              pc += 1
            when :i32_clz
              v = vstack.pop & I32_MASK
              vstack << (v.zero? ? 32 : 32 - v.bit_length)
              pc += 1
            when :i32_ctz
              v = vstack.pop & I32_MASK
              if v.zero?
                vstack << 32
              else
                n = 0
                n += 1 while ((v >> n) & 1).zero?
                vstack << n
              end
              pc += 1
            when :i32_popcnt
              vstack << (vstack.pop & I32_MASK).to_s(2).count("1")
              pc += 1
            when :i32_div_u
              b = vstack.pop; a = vstack.pop
              raise Trap, "integer divide by zero" if b.zero?

              vstack << (a / b)
              pc += 1
            when :i32_div_s
              b = Wasm.to_s32(vstack.pop); a = Wasm.to_s32(vstack.pop)
              raise Trap, "integer divide by zero" if b.zero?
              raise Trap, "integer overflow" if a == -0x8000_0000 && b == -1

              # Truncate toward zero
              q = a.abs / b.abs
              q = -q if (a < 0) ^ (b < 0)
              vstack << (q & I32_MASK)
              pc += 1
            when :i32_rem_u
              b = vstack.pop; a = vstack.pop
              raise Trap, "integer divide by zero" if b.zero?

              vstack << (a % b)
              pc += 1
            when :i32_rem_s
              b = Wasm.to_s32(vstack.pop); a = Wasm.to_s32(vstack.pop)
              raise Trap, "integer divide by zero" if b.zero?

              r = a.abs % b.abs
              r = -r if a < 0
              vstack << (r & I32_MASK)
              pc += 1
            when :i64_add
              b = vstack.pop; a = vstack.pop
              vstack << ((a + b) & I64_MASK)
              pc += 1
            when :i64_sub
              b = vstack.pop; a = vstack.pop
              vstack << ((a - b) & I64_MASK)
              pc += 1
            when :i64_mul
              b = vstack.pop; a = vstack.pop
              vstack << ((a * b) & I64_MASK)
              pc += 1
            when :i64_and
              b = vstack.pop; a = vstack.pop
              vstack << ((a & b) & I64_MASK)
              pc += 1
            when :i64_or
              b = vstack.pop; a = vstack.pop
              vstack << ((a | b) & I64_MASK)
              pc += 1
            when :i64_xor
              b = vstack.pop; a = vstack.pop
              vstack << ((a ^ b) & I64_MASK)
              pc += 1
            when :i64_shl
              b = vstack.pop; a = vstack.pop
              vstack << ((a << (b & 63)) & I64_MASK)
              pc += 1
            when :i64_shr_u
              b = vstack.pop; a = vstack.pop
              vstack << ((a & I64_MASK) >> (b & 63))
              pc += 1
            when :i64_shr_s
              b = vstack.pop; a = Wasm.to_s64(vstack.pop)
              shift = b & 63
              vstack << ((a >> shift) & I64_MASK)
              pc += 1
            when :i64_rotl
              b = vstack.pop; a = vstack.pop & I64_MASK
              n = b & 63
              vstack << (((a << n) | (a >> (64 - n))) & I64_MASK)
              pc += 1
            when :i64_rotr
              b = vstack.pop; a = vstack.pop & I64_MASK
              n = b & 63
              vstack << (((a >> n) | (a << (64 - n))) & I64_MASK)
              pc += 1
            when :i64_eqz
              vstack << (vstack.pop.zero? ? 1 : 0)
              pc += 1
            when :i64_eq
              b = vstack.pop; a = vstack.pop
              vstack << (a == b ? 1 : 0)
              pc += 1
            when :i64_ne
              b = vstack.pop; a = vstack.pop
              vstack << (a == b ? 0 : 1)
              pc += 1
            when :i64_lt_u
              b = vstack.pop; a = vstack.pop
              vstack << (a < b ? 1 : 0)
              pc += 1
            when :i64_lt_s
              b = Wasm.to_s64(vstack.pop); a = Wasm.to_s64(vstack.pop)
              vstack << (a < b ? 1 : 0)
              pc += 1
            when :i64_gt_u
              b = vstack.pop; a = vstack.pop
              vstack << (a > b ? 1 : 0)
              pc += 1
            when :i64_gt_s
              b = Wasm.to_s64(vstack.pop); a = Wasm.to_s64(vstack.pop)
              vstack << (a > b ? 1 : 0)
              pc += 1
            when :i64_le_u
              b = vstack.pop; a = vstack.pop
              vstack << (a <= b ? 1 : 0)
              pc += 1
            when :i64_le_s
              b = Wasm.to_s64(vstack.pop); a = Wasm.to_s64(vstack.pop)
              vstack << (a <= b ? 1 : 0)
              pc += 1
            when :i64_ge_u
              b = vstack.pop; a = vstack.pop
              vstack << (a >= b ? 1 : 0)
              pc += 1
            when :i64_ge_s
              b = Wasm.to_s64(vstack.pop); a = Wasm.to_s64(vstack.pop)
              vstack << (a >= b ? 1 : 0)
              pc += 1
            when :i64_div_u
              b = vstack.pop; a = vstack.pop
              raise Trap, "integer divide by zero" if b.zero?

              vstack << (a / b)
              pc += 1
            when :i64_clz
              v = vstack.pop & I64_MASK
              vstack << (v.zero? ? 64 : 64 - v.bit_length)
              pc += 1
            when :i64_ctz
              v = vstack.pop & I64_MASK
              if v.zero?
                vstack << 64
              else
                n = 0
                n += 1 while ((v >> n) & 1).zero?
                vstack << n
              end
              pc += 1
            when :i32_wrap_i64
              vstack << (vstack.pop & I32_MASK)
              pc += 1
            when :i64_extend_i32_u
              vstack << (vstack.pop & I32_MASK)
              pc += 1
            when :i64_extend_i32_s
              vstack << (Wasm.to_s32(vstack.pop) & I64_MASK)
              pc += 1
            when :i32_extend8_s
              v = vstack.pop & 0xFF
              v -= 0x100 if v >= 0x80
              vstack << (v & I32_MASK)
              pc += 1
            when :i32_extend16_s
              v = vstack.pop & 0xFFFF
              v -= 0x10000 if v >= 0x8000
              vstack << (v & I32_MASK)
              pc += 1
            when :i64_extend8_s
              v = vstack.pop & 0xFF
              v -= 0x100 if v >= 0x80
              vstack << (v & I64_MASK)
              pc += 1
            when :i64_extend16_s
              v = vstack.pop & 0xFFFF
              v -= 0x10000 if v >= 0x8000
              vstack << (v & I64_MASK)
              pc += 1
            when :i64_extend32_s
              v = vstack.pop & I32_MASK
              v -= I32_RANGE if v >= I32_SIGN
              vstack << (v & I64_MASK)
              pc += 1
            when :drop
              vstack.pop
              pc += 1
            when :select
              cond = vstack.pop
              v2 = vstack.pop
              v1 = vstack.pop
              vstack << (cond.zero? ? v2 : v1)
              pc += 1
            when :call
              callee_idx = instr[1]
              callee = @instance.funcs[callee_idx]
              n = callee.type.params.size
              args2 = vstack.pop(n)
              result = invoke(callee_idx, args2)
              push_results(vstack, result, callee.type.results.size)
              pc += 1
            when :call_indirect
              type_idx = instr[1]
              table_entry = vstack.pop
              callee_idx = @instance.table[table_entry]
              raise Trap, "null funcref" if callee_idx.nil?

              callee = @instance.funcs[callee_idx]
              expected = @instance.types[type_idx]
              if callee.type.params != expected.params || callee.type.results != expected.results
                raise Trap, "indirect call type mismatch"
              end

              n = callee.type.params.size
              args2 = vstack.pop(n)
              result = invoke(callee_idx, args2)
              push_results(vstack, result, callee.type.results.size)
              pc += 1
            when :return_
              return finish(vstack, ftype)
            when :br_table
              idx = vstack.pop
              depth = idx < instr[1].size ? instr[1][idx] : instr[2]
              pc = do_branch(label_stack, vstack, depth)
              return finish(vstack, ftype) if label_stack.empty?
            when :memory_size
              vstack << @instance.memory.size_pages
              pc += 1
            when :memory_grow
              vstack << @instance.memory.grow(vstack.pop)
              pc += 1
            when :unreachable
              raise Trap, "unreachable executed"
            when :nop
              pc += 1
            else
              raise Trap, "unimplemented op #{op.inspect} at pc=#{pc}"
            end
          end

          finish(vstack, ftype)
        end

        # Branch to label depth N: pop arity vals, drop N+1 labels, restore
        # value stack to that label's base height, re-push the saved vals,
        # return the target pc. For loops, target points back at the loop op
        # which will re-push a fresh label on re-execution.
        def do_branch(label_stack, vstack, depth)
          label = label_stack[label_stack.size - 1 - depth]
          target_pc, arity, base_height, _is_loop = label
          saved = arity.positive? ? vstack.last(arity) : []
          (depth + 1).times { label_stack.pop }
          vstack.slice!(base_height..)
          saved.each { |v| vstack << v }
          target_pc
        end

        def block_result_arity(blocktype)
          case blocktype[0]
          when :empty then 0
          when :value then 1
          when :typeidx
            @instance.types[blocktype[1]].results.size
          end
        end

        def block_param_arity(blocktype)
          case blocktype[0]
          when :empty, :value then 0
          when :typeidx
            @instance.types[blocktype[1]].params.size
          end
        end

        def push_results(vstack, result, expected)
          case expected
          when 0 then nil
          when 1
            vstack << result
          else
            result.each { |v| vstack << v }
          end
        end

        def finish(vstack, ftype)
          case ftype.results.size
          when 0 then nil
          when 1 then vstack.last
          else vstack.last(ftype.results.size)
          end
        end
      end
    end
  end
end
