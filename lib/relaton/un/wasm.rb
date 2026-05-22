# frozen_string_literal: true

module Relaton
  module Un
    module Wasm
      class Trap < StandardError; end
      class DecodeError < StandardError; end
      class LinkError < StandardError; end
    end
  end
end

require_relative "wasm/memory"
require_relative "wasm/decoder"
require_relative "wasm/module"
require_relative "wasm/interpreter"
require_relative "wasm/instance"
