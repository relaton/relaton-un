# frozen_string_literal: true

module Relaton
  module Un
    module Wasm
      class Memory
        PAGE = 65_536

        attr_reader :max_pages

        def initialize(initial_pages:, max_pages: nil)
          @pages = initial_pages
          @max_pages = max_pages
          @buf = String.new("\x00".b * (initial_pages * PAGE), encoding: Encoding::ASCII_8BIT)
        end

        def size_pages
          @pages
        end

        def grow(delta)
          new_pages = @pages + delta
          return -1 if @max_pages && new_pages > @max_pages

          old = @pages
          @pages = new_pages
          @buf << ("\x00".b * (delta * PAGE))
          old
        end

        def read(addr, len)
          bounds!(addr, len)
          @buf.byteslice(addr, len)
        end

        def write(addr, bytes)
          bytes = bytes.b
          bounds!(addr, bytes.bytesize)
          @buf.bytesplice(addr, bytes.bytesize, bytes)
        end

        def load_u8(addr)
          bounds!(addr, 1)
          @buf.getbyte(addr)
        end

        def load_i8(addr)
          v = load_u8(addr)
          v >= 0x80 ? v - 0x100 : v
        end

        def load_u16(addr)
          bounds!(addr, 2)
          @buf.byteslice(addr, 2).unpack1("v")
        end

        def load_i16(addr)
          v = load_u16(addr)
          v >= 0x8000 ? v - 0x10000 : v
        end

        def load_u32(addr)
          bounds!(addr, 4)
          @buf.byteslice(addr, 4).unpack1("V")
        end

        def load_i32(addr)
          v = load_u32(addr)
          v >= 0x8000_0000 ? v - 0x1_0000_0000 : v
        end

        def load_u64(addr)
          bounds!(addr, 8)
          @buf.byteslice(addr, 8).unpack1("Q<")
        end

        def load_i64(addr)
          v = load_u64(addr)
          v >= 0x8000_0000_0000_0000 ? v - 0x1_0000_0000_0000_0000 : v
        end

        def store_u8(addr, val)
          bounds!(addr, 1)
          @buf.setbyte(addr, val & 0xff)
        end

        def store_u16(addr, val)
          bounds!(addr, 2)
          @buf.bytesplice(addr, 2, [val & 0xffff].pack("v"))
        end

        def store_u32(addr, val)
          bounds!(addr, 4)
          @buf.bytesplice(addr, 4, [val & 0xffff_ffff].pack("V"))
        end

        def store_u64(addr, val)
          bounds!(addr, 8)
          @buf.bytesplice(addr, 8, [val & 0xffff_ffff_ffff_ffff].pack("Q<"))
        end

        private

        def bounds!(addr, len)
          return if addr >= 0 && addr + len <= @buf.bytesize

          raise Trap, "out of bounds memory access (addr=#{addr}, len=#{len}, size=#{@buf.bytesize})"
        end
      end
    end
  end
end
