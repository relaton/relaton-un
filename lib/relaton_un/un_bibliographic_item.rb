module RelatonUn
  class UnBibliographicItem < RelatonIsoBib::IsoBibliographicItem
    TYPES = %w[
      recommendation plenary addendum communication corrigendum reissue agenda
      budgetary sec-gen-notes expert-report resolution
    ].freeze

    DISTRIBUTIONS = { "GEN" => "general", "LTD" => "limited",
                      "DER" => "restricted" }.freeze

    # @return [RelatonUn::Session, NilClass]
    attr_reader :session

    # @return [String, NilClass]
    attr_reader :distribution

    # @param session [RelatonUn::Session, NilClass]
    # @param distribution [String]
    def initialize(**args)
      if args[:distribution] && !DISTRIBUTIONS.has_value?(args[:distribution])
        warn "[relaton-un] WARNING: invalid distribution: #{args[:distribution]}"
      end
      @distribution = args.delete :distribution
      @session = args.delete :session
      super **args
    end

    # @param builder [Nokogiri::XML::Builder]
    # @param bibdata [TrueClasss, FalseClass, NilClass]
    def to_xml(builder = nil, **opts)
      super(builder, **opts) do |b|
        b.distribution distribution if distribution
        session&.to_xml b if session
      end
    end

    # @return [Hash]
    def to_hash
      hash = super
      hash["session"] = session.to_hash if session
      hash
    end
  end
end
