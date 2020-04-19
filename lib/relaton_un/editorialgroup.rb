module RelatonUn
  class EditorialGroup
    include RelatonBib

    # @return [Array<String>]
    attr_reader :committee

    # @param committee [Array<String>]
    def initialize(committee)
      @committee = committee
    end

    # @param builder [Nokogiri::XML::Builder]
    def to_xml(builder)
      builder.editorialgroup do |b|
        committee.each { |c| b.committee c }
      end
    end

    # @return [Array<Hash>, Hash]
    def to_hash
      single_element_array(committee.map { |c| { "committee" => c } })
    end
  end
end
