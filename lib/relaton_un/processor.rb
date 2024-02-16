require "relaton/processor"

module RelatonUn
  class Processor < Relaton::Processor
    attr_reader :idtype

    def initialize
      @short = :relaton_un
      @prefix = "UN"
      @defaultprefix = %r{^UN\s}
      @idtype = "UN"
    end

    # @param code [String]
    # @param date [String, NilClass] year
    # @param opts [Hash]
    # @return [RelatonUn::UnBibliographicItem]
    def get(code, date, opts)
      # ::RelatonUn::UnBibliography.get(code, date, opts)
    end

    # @param xml [String]
    # @return [RelatonUn::UnBibliographicItem]
    def from_xml(xml)
      ::RelatonUn::XMLParser.from_xml xml
    end

    # @param hash [Hash]
    # @return [RelatonUn::UnBibliographicItem]
    def hash_to_bib(hash)
      item_hash = ::RelatonUn::HashConverter.hash_to_bib(hash)
      ::RelatonUn::UnBibliographicItem.new(**item_hash)
    end

    # Returns hash of XML grammar
    # @return [String]
    def grammar_hash
      @grammar_hash ||= ::RelatonUn.grammar_hash
    end
  end
end
