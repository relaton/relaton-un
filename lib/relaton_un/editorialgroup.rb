module RelatonUn
  class EditorialGroup
    include RelatonBib

    # @return [Array<String>]
    attr_reader :committee

    # @param committee [Array<String>]
    def initialize(committee)
      @committee = committee
    end

    # @return [true]
    def presence?
      true
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

    # @param prefix [String]
    # @return [String]
    def to_asciibib(prefix)
      pref = prefix.empty? ? prefix : prefix + "."
      pref += "editorialgroup"
      committee.map { |c| "#{pref}.committee:: #{c}\n" }.join
    end
  end
end
