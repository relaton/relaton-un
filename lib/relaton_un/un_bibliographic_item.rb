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
        Util.warn "WARNING: invalid distribution: `#{args[:distribution]}`"
      end
      @submissionlanguage = args.delete :submissionlanguage
      @distribution = args.delete :distribution
      @session = args.delete :session
      @job_number = args.delete :job_number
      super(**args)
    end

    #
    # Fetches flavor schema version.
    #
    # @return [String] flavor schema version
    #
    def ext_schema
      @ext_schema ||= schema_versions["relaton-model-un"]
    end

    # @param opts [Hash]
    # @option opts [Nokogiri::XML::Builder] :builder XML builder
    # @option opts [Boolean] :bibdata
    # @option opts [String] :lang language
    # @return [String] XML
    def to_xml(**opts) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
      super(**opts) do |b|
        ext = b.ext do
          b.doctype doctype if doctype
          submissionlanguage&.each { |sl| b.submissionlanguage sl }
          editorialgroup&.to_xml b
          ics&.each { |i| i.to_xml b }
          b.distribution distribution if distribution
          session&.to_xml b
          b.job_number job_number if job_number
        end
        ext["schema-version"] = ext_schema unless opts[:embedded]
      end
    end

    #
    # Renders the document as a hash.
    #
    # @param embedded [Boolean] embedded in another document
    #
    # @return [Hash]
    #
    def to_hash(embedded: false) # rubocop:disable Metrics/AbcSize
      hash = super
      if submissionlanguage&.any?
        hash["submissionlanguage"] = single_element_array submissionlanguage
      end
      hash["distribution"] = distribution if distribution
      hash["session"] = session.to_hash if session
      hash["job_number"] = job_number if job_number
      hash
    end

    # @param prefix [String]
    # @return [String]
    def to_asciibib(prefix = "") # rubocop:disable Metrics/AbcSize
      pref = prefix.empty? ? prefix : "#{prefix}."
      out = super
      submissionlanguage.each do |sl|
        out += "#{pref}submissionlanguage:: #{sl}\n"
      end
      out += "#{pref}distribution:: #{distribution}\n" if distribution
      out += session.to_asciibib prefix if session
      out += "#{pref}job_number:: #{job_number}\n" if job_number
      out
    end
  end
end
