# frozen_string_literal: true

require "faraday"
require "json"
require "securerandom"

module Relaton
  module Un
    class HitCollection < Core::HitCollection
      API_BASE = "https://documents.un.org/api"

      # Factory method — performs the API search and populates hits.
      # @param text [String] symbol to search for
      # @return [HitCollection]
      def self.search(text)
        hc = new(text)
        hc.send(:fetch_hits)
        hc
      end

      private

      def fetch_hits
        response = search_api(@ref)
        response&.each { |data| @array << Hit.new(data, self) }
      end

      def search_api(text) # rubocop:disable Metrics/MethodLength
        resp = connection.post("search?l=en&rid=#{SecureRandom.uuid}") do |req|
          req.headers["Content-Type"] = "application/json"
          req.body = JSON.generate(search_body(text))
        end
        return unless resp.success?

        body = JSON.parse(resp.body)
        return unless body["status"] == 1

        body.dig("body", "data")
      end

      def search_body(text) # rubocop:disable Metrics/MethodLength
        {
          symbol: text, jobNumber: "", publicationDate: "* TO *",
          releaseDate: "* TO *", title: "", subject: "", session: "",
          agenda: "", truncation: false,
          fullTextSearch: { language: "en", searchText: "" },
          sortOptions: { sortField: "Sort by relevance" },
          pagination: { currentPage: 1, itemsPerPage: 20 },
          screenLanguage: "en", tcodes: [],
        }
      end

      def connection
        @connection ||= Faraday.new(url: API_BASE) do |f|
          f.headers["Authorization"] = "Access #{TokenGenerator.generate}"
          f.headers["Cache-Control"] = "public, max-age=0"
        end
      end
    end
  end
end
