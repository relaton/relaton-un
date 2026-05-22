# frozen_string_literal: true

module Relaton
  module Un
    # Class methods for search UN standards.
    class Bibliography
      class << self
        # @param text [String]
        # @return [Relaton::Un::HitCollection]
        def search(text)
          HitCollection.search text
        rescue Faraday::ConnectionFailed, Faraday::TimeoutError,
               Faraday::SSLError => e
          raise Relaton::RequestError,
                "Could not access #{HitCollection::API_BASE}: #{e.message}"
        end

        # @param ref [String] document reference
        # @param year [String, NilClass]
        # @param opts [Hash] options
        # @return [Relaton::Bib::ItemData]
        def get(ref, _year = nil, _opts = {})
          Util.info "Fetching from documents.un.org ...", key: ref
          /^(?:UN\s)?(?<code>.*)/ =~ ref
          result = isobib_search_filter(code)
          if result
            Util.info "Found: `#{result.item.docidentifier[0].content}`", key: ref
            result.item
          else
            Util.info "Not found.", key: ref
            nil
          end
        end

        private

        # Search for hits.
        #
        # @param code [String] reference without correction
        # @return [Relaton::Un::Hit, nil]
        def isobib_search_filter(code)
          result = search(code)
          result.select { |i| i.hit["symbols"]&.compact&.include?(code) }.first
        end
      end
    end
  end
end
