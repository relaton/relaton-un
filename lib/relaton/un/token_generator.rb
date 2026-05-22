# frozen_string_literal: true

require_relative "wasm"

module Relaton
  module Un
    module TokenGenerator
      WASM_PATH = File.join(__dir__, "wasm_v_bg.wasm")
      DOMAIN = "documents.un.org"

      # Generates an auth token for the UN documents API.
      # Tokens are cached per-minute since the WASM output changes each minute.
      # @return [String] decimal string representation of the i64 token
      def self.generate
        now = Time.now.utc
        key = [now.year, now.month, now.day, now.hour, now.min]
        return @cached_token if @cached_key == key && @cached_token

        @cached_key = key
        @cached_token = call_wasm(*key)
      end

      def self.call_wasm(year, month, day, hour, minute)
        mod = (@module ||= Wasm::Module.parse(File.binread(WASM_PATH)))
        heap = Heap.new
        fake_window = Object.new
        fake_location = Object.new
        heap.alloc(fake_window)   # index 4
        heap.alloc(fake_location) # index 5

        imports = { "wbg" => build_imports(heap, fake_window, fake_location) }
        instance = Wasm::Instance.new(mod, imports)
        instance.invoke("check", year, month, day, hour, minute).to_s
      end

      def self.build_imports(heap, fake_window, fake_location) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        w = {}
        w["__wbindgen_object_drop_ref"] = ->(_c, idx) { heap.drop(idx); nil }
        w["__wbg_instanceof_Window_acc97ff9f5d2c7b4"] = ->(_c, _idx) { 1 }
        w["__wbg_location_8cc8ccf27e342c0a"] = ->(_c, _idx) { heap.alloc(fake_location) }
        w["__wbg_newnoargs_b5b063fc6c2f0376"] = ->(_c, _ptr, _len) { heap.alloc(Object.new) }
        w["__wbg_call_97ae9d8645dc388b"] = ->(_c, _f, _t) { heap.alloc(fake_window) }
        w["__wbindgen_object_clone_ref"] = ->(_c, idx) { heap.alloc(heap.get(idx)) }
        %w[
          __wbg_self_6d479506f72c6a71
          __wbg_window_f2557cc78490aceb
          __wbg_globalThis_7f206bda628d5286
          __wbg_global_ba75c50d1cf384f4
        ].each { |name| w[name] = ->(_c) { heap.alloc(fake_window) } }
        w["__wbindgen_is_undefined"] = ->(_c, idx) { heap.get(idx) == :undefined ? 1 : 0 }
        w["__wbindgen_debug_string"] = ->(_c, _ret_ptr, _idx) { nil }
        w["__wbindgen_throw"] = lambda do |caller, ptr, len|
          mem = caller.export("memory").to_memory
          raise mem.read(ptr, len)
        end
        w["__wbg_host_f82dbbd8bb5ef24a"] = lambda do |caller, ret_ptr, _loc_idx|
          mem = caller.export("memory").to_memory
          malloc = caller.export("__wbindgen_malloc").to_func
          host_bytes = DOMAIN.encode("utf-8")
          ptr = malloc.call(host_bytes.bytesize)
          mem.write(ptr, host_bytes)
          mem.write(ret_ptr, [ptr, host_bytes.bytesize].pack("V2"))
          nil
        end
        w
      end

      # Manages a slab-allocated heap of Ruby objects indexed by i32,
      # mirroring wasm-bindgen's JS object heap.
      class Heap
        BUILTINS = 36

        def initialize
          # Indices 0-3 mirror wasm-bindgen's builtin slots:
          # 0 = undefined, 1 = null, 2 = true, 3 = false
          @slab = [:undefined, nil, true, false]
          @free_head = @slab.length
        end

        def get(idx)
          @slab[idx]
        end

        def alloc(obj)
          if @free_head >= @slab.length
            @slab << (@slab.length + 1)
          end
          idx = @free_head
          @free_head = @slab[idx]
          @slab[idx] = obj
          idx
        end

        def drop(idx)
          return if idx < BUILTINS

          @slab[idx] = @free_head
          @free_head = idx
        end
      end

      private_class_method :call_wasm, :build_imports
    end
  end
end
