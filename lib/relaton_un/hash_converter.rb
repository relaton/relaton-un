module RelatonUn
  class HashConverter < RelatonBib::HashConverter
    class << self
      # @override RelatonIsoBib::HashConverter.hash_to_bib
      # @param args [Hash]
      # @param nested [TrueClass, FalseClass]
      # @return [Hash]
      def hash_to_bib(args, nested = false)
        ret = super
        return if ret.nil?

        ret[:submissionlanguage] = array ret[:submissionlanguage]
        session_hash_to_bib ret
        ret
      end

      private

      # @param ret [Hash]
      def session_hash_to_bib(ret)
        ret[:session] = Session.new(ret[:session]) if ret[:session]
      end

      # @param ret [Hash]
      def editorialgroup_hash_to_bib(ret)
        eg = ret[:editorialgroup]
        return unless eg

        committee = eg.map { |e| e[:committee] }
        ret[:editorialgroup] = EditorialGroup.new array(committee)
      end
    end
  end
end
