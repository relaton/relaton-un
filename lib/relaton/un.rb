require "addressable"
require "relaton/bib"
require_relative "un/version"
require_relative "un/util"
require_relative "un/item_data"
require_relative "un/item"
require_relative "un/bibitem"
require_relative "un/bibdata"
require_relative "un/token_generator"
require_relative "un/parser"
require_relative "un/hit"
require_relative "un/hit_collection"
require_relative "un/bibliography"

module Relaton
  module Un
    class Error < StandardError; end

    # Returns hash of XML reammar
    # @return [String]
    def self.grammar_hash
      # gem_path = File.expand_path "..", __dir__
      # grammars_path = File.join gem_path, "grammars", "*"
      # grammars = Dir[grammars_path].sort.map { |gp| File.read gp }.join
      Digest::MD5.hexdigest Relaton::Un::VERSION + Relaton::Bib::VERSION # grammars
    end
  end
end
