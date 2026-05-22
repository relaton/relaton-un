# frozen_string_literal: true

module Relaton
  module Un
    module Wasm
      class Instance
        attr_reader :memory, :funcs, :types, :globals, :table

        # imports: { "modname" => { "fieldname" => Proc } }
        def initialize(mod, imports = {})
          @mod = mod
          @types = mod.types
          @imports = imports
          @funcs = []
          @globals = []
          @table = []
          link_funcs
          init_memory
          init_globals
          init_table
          init_data
          @interpreter = Interpreter.new(self)
        end

        def invoke(name, *args)
          idx = export_index(name, :func)
          invoke_by_index(idx, args)
        end

        def invoke_by_index(func_idx, args)
          @interpreter.invoke(func_idx, args)
        end

        def export_index(name, kind)
          exp = @mod.exports.find { |e| e.name == name && e.kind == kind }
          raise LinkError, "no export named #{name} of kind #{kind}" unless exp

          exp.index
        end

        private

        def link_funcs
          @mod.imports.each do |imp|
            next unless imp.kind == :func

            type = @types[imp.desc]
            proc_ = @imports.dig(imp.mod, imp.field)
            raise LinkError, "missing import #{imp.mod}.#{imp.field}" unless proc_

            @funcs << FuncRef.new(type, :import, nil, proc_)
          end

          @mod.code.each_with_index do |code, i|
            type_idx = @mod.function_type_indices[@mod.imported_function_count + i]
            type = @types[type_idx]
            @funcs << FuncRef.new(type, :wasm, code, nil)
          end
        end

        def init_memory
          mem = @mod.memories.first
          @memory = mem ? Memory.new(initial_pages: mem.initial, max_pages: mem.max) : nil
        end

        def init_globals
          @mod.globals.each do |g|
            @globals << eval_const(g.init_expr)
          end
        end

        def init_table
          tbl = @mod.tables.first
          @table = Array.new(tbl.initial, nil) if tbl

          @mod.elements.each do |e|
            offset = eval_const(e.offset_expr)
            e.func_indices.each_with_index do |fi, i|
              @table[offset + i] = fi
            end
          end
        end

        def init_data
          @mod.data.each do |d|
            offset = eval_const(d.offset_expr)
            @memory.write(offset, d.bytes)
          end
        end

        def eval_const(expr)
          case expr[0]
          when :i32_const, :i64_const then expr[1]
          when :global_get then @globals[expr[1]]
          else raise LinkError, "bad const expr #{expr.inspect}"
          end
        end
      end
    end
  end
end
