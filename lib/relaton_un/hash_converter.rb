module RelatonUn
  module HashConverter
    include RelatonBib::HashConverter
    extend self
    # @override RelatonIsoBib::HashConverter.hash_to_bib
    # @param args [Hash]
    # @param nested [TrueClass, FalseClass]
    # @return [Hash]
    def hash_to_bib(args)
      ret = super
      return if ret.nil?

      hash_to_bib_submissions ret
      session_hash_to_bib ret
      ret[:distribution] = ret[:ext][:distribution] if ret.dig(:ext, :distribution)
      ret[:job_number] = ret[:ext][:job_number] if ret.dig(:ext, :job_number)
      ret
    end

    private

    def hash_to_bib_submissions(ret)
      sm = ret.dig(:ext, :submissionlanguage) || ret[:submissionlanguage] # @TODO remove args[:submissionlanguage] after all gems are updated
      return unless sm

      ret[:submissionlanguage] = RelatonBib.array sm
    end

    # @param ret [Hash]
    def session_hash_to_bib(ret)
      session = ret.dig(:ext, :session) || ret[:session] # @TODO remove ret[:session] after all gems are updated
      return unless session

      ret[:session] = Session.new(**session)
    end

    # @param ret [Hash]
    def editorialgroup_hash_to_bib(ret)
      eg = ret.dig(:ext, :editorialgroup) || ret[:editorialgroup] # @TODO remove ret[:editorialgroup] after all gems are updated
      return unless eg

      committee = eg.map { |e| e[:committee] }
      ret[:editorialgroup] = EditorialGroup.new RelatonBib.array(committee)
    end

    def create_doctype(**args)
      DocumentType.new(**args)
    end
  end
end
