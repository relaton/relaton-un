# frozen_string_literal: true

module Relaton
  module Un
    module Wasm
      FuncType = Struct.new(:params, :results)
      Import   = Struct.new(:mod, :field, :kind, :desc)
      Export   = Struct.new(:name, :kind, :index)
      Global   = Struct.new(:type, :mutable, :init_expr)
      Element  = Struct.new(:table_idx, :offset_expr, :func_indices)
      Data     = Struct.new(:mem_idx, :offset_expr, :bytes)
      Code     = Struct.new(:locals, :body)

      MemoryType = Struct.new(:initial, :max)
      TableType  = Struct.new(:elem_type, :initial, :max)

      class Module
        attr_reader :types, :imports, :function_type_indices, :tables, :memories,
                    :globals, :exports, :elements, :code, :data, :start

        def initialize
          @types = []
          @imports = []
          @function_type_indices = []
          @tables = []
          @memories = []
          @globals = []
          @exports = []
          @elements = []
          @code = []
          @data = []
          @start = nil
        end

        def self.parse(bytes)
          Decoder.new(bytes).decode
        end

        # Number of imported functions (they precede module-defined functions
        # in the funcidx space).
        def imported_function_count
          @imports.count { |i| i.kind == :func }
        end
      end
    end
  end
end
