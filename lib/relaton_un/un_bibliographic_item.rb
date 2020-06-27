module RelatonUn
  class UnBibliographicItem < RelatonBib::BibliographicItem
    include RelatonBib

    TYPES = %w[
      recommendation plenary addendum communication corrigendum reissue agenda
      budgetary sec-gen-notes expert-report resolution
    ].freeze

    DISTRIBUTIONS = { "GEN" => "general", "LTD" => "limited",
                      "DER" => "restricted", "PRO" => "provisional" }.freeze

    # @return [RelatonUn::Session, NilClass]
    attr_reader :session

    # @return [String, NilClass]
    attr_reader :distribution, :job_number

    # @return [Array<String>]
    attr_reader :submissionlanguage

    # @param session [RelatonUn::Session, NilClass]
    # @param distribution [String, nil]
    # @param job_number [String, nil]
    def initialize(**args)
      if args[:distribution] && !DISTRIBUTIONS.has_value?(args[:distribution])
        warn "[relaton-un] WARNING: invalid distribution: #{args[:distribution]}"
      end
      @submissionlanguage = args.delete :submissionlanguage
      @distribution = args.delete :distribution
      @session = args.delete :session
      @job_number = args.delete :job_number
      super **args
    end

    # @param builder [Nokogiri::XML::Builder]
    # @param bibdata [TrueClasss, FalseClass, NilClass]
    def to_xml(builder = nil, **opts)
      super(builder, **opts) do |b|
        b.ext do
          b.doctype doctype if doctype
          submissionlanguage&.each { |sl| b.submissionlanguage sl }
          editorialgroup&.to_xml b
          ics&.each { |i| i.to_xml b }
          b.distribution distribution if distribution
          session&.to_xml b if session
          b.job_number job_number if job_number
        end
      end
    end

    # @return [Hash]
    def to_hash
      hash = super
      if submissionlanguage&.any?
        hash["submissionlanguage"] = single_element_array submissionlanguage
      end
      hash["distribution"] = distribution if distribution
      hash["session"] = session.to_hash if session
      hash["job_number"] = job_number if job_number
      hash
    end
  end
end
