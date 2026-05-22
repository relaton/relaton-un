# frozen_string_literal: true

module Relaton
  module Un
    class Parser
      DISTRIBUTIONS = { "GEN" => "general", "LTD" => "limited",
                        "DER" => "restricted", "PRO" => "provisional" }.freeze

      def initialize(hit)
        @hit = hit
      end

      # @return [Relaton::Un::ItemData]
      def parse # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        ItemData.new(
          type: "standard",
          fetched: Date.today.to_s,
          docidentifier: fetch_docid,
          docnumber: @hit["symbol"],
          language: ["en"],
          script: ["Latn"],
          title: fetch_title,
          date: fetch_date,
          source: fetch_link,
          keyword: fetch_keyword,
          ext: Ext.new(
            session: fetch_session,
            distribution: fetch_distribution,
            job_number: fetch_job_number,
          ),
        )
      end

      private

      # @return [Array<Relaton::Bib::Docidentifier>]
      def fetch_docid
        symbols = @hit["symbols"]&.compact&.reject(&:empty?) || []
        dids = symbols.map { |s| Bib::Docidentifier.new(content: s, type: "UN") }
        dids.first.primary = true unless dids.empty?
        dids
      end

      # @return [Array<Relaton::Bib::Title>]
      def fetch_title
        title = english_data&.dig("title") || ""
        Bib::Title.from_string title, "en", "Latn"
      end

      # @return [Array<Relaton::Bib::Date>]
      def fetch_date
        d = []
        if (pub = @hit["publication_date"])
          d << Bib::Date.new(type: "published", at: pub[0, 10])
        end
        if (rel = english_data&.dig("release_date"))
          d << Bib::Date.new(type: "issued", at: rel[0, 10])
        end
        d
      end

      # @return [Array<Relaton::Bib::Uri>]
      def fetch_link
        jn = fetch_job_number
        return [] unless jn && !jn.empty?

        [Bib::Uri.new(
          content: "https://documents.un.org/api/symbol/access?j=#{jn}&t=pdf",
          type: "pdf",
        )]
      end

      # @return [Array<Relaton::Bib::Keyword>]
      def fetch_keyword
        subjects = english_data&.dig("subjects") || []
        subjects.map do |kw|
          Bib::Keyword.new(vocab: Bib::LocalizedString.new(content: kw))
        end
      end

      # @return [Relaton::Un::Session]
      def fetch_session
        session_num = @hit["sessions"]&.compact&.reject(&:empty?)&.first
        agenda = @hit["agendas"]&.compact&.reject(&:empty?)&.first
        Session.new(number: session_num, agenda_id: agenda)
      end

      # @return [String, nil]
      def fetch_distribution
        DISTRIBUTIONS[@hit["distribution"]]
      end

      # @return [String, nil]
      def fetch_job_number
        en = english_data
        jn = en&.dig("job_number")
        return jn if jn && !jn.empty?

        @hit["job_numbers"]&.compact&.reject(&:empty?)&.first
      end

      # @return [Hash, nil] the English perLanguage entry
      def english_data
        @english_data ||= @hit["perLanguage"]&.find { |pl| pl["language"] == "English" }
      end
    end
  end
end
