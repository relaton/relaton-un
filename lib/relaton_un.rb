require "addressable"
require "relaton_bib"
require "relaton_un/version"
require "relaton_un/util"
require "relaton_un/document_type"
require "relaton_un/un_bibliographic_item"
require "relaton_un/un_bibliography"
require "relaton_un/hit_collection"
require "relaton_un/hit"
require "relaton_un/hash_converter"
require "relaton_un/xml_parser"
require "relaton_un/session"
require "relaton_un/editorialgroup"

module RelatonUn
  class Error < StandardError; end

  # Returns hash of XML reammar
  # @return [String]
  def self.grammar_hash
    # gem_path = File.expand_path "..", __dir__
    # grammars_path = File.join gem_path, "grammars", "*"
    # grammars = Dir[grammars_path].sort.map { |gp| File.read gp }.join
    Digest::MD5.hexdigest RelatonUn::VERSION + RelatonBib::VERSION # grammars
  end
end
