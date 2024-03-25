# frozen_string_literal: true

module RelatonUn
  # Class methods for search ISO standards.
  class UnBibliography
    class << self
      # @param text [String]
      # @return [RelatonUn::HitCollection]
      def search(text)
        HitCollection.new text
      rescue SocketError, Errno::EINVAL, Errno::ECONNRESET, EOFError,
             Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
             Net::ProtocolError, Net::ReadTimeout, Net::OpenTimeout,
             OpenSSL::SSL::SSLError, Errno::ETIMEDOUT => e
        raise RelatonBib::RequestError,
              "Could not access #{HitCollection::DOMAIN}: #{e.message}"
      end

      # @param ref [String] document reference
      # @param year [String, NilClass]
      # @param opts [Hash] options
      # @return [RelatonUn::UnBibliographicItem]
      def get(ref, _year = nil, _opts = {})
        Util.info "Fetching from documents.un.org ...", key: ref
        /^(?:UN\s)?(?<code>.*)/ =~ ref
        result = isobib_search_filter(code)
        if result
          Util.info "Found: `#{result.fetch.docidentifier[0].id}`", key: ref
          result.fetch
        else
          Util.info "Not found.", key: ref
          nil
        end
      end

      private

      # Search for hits.
      #
      # @param code [String] reference without correction
      # @return [RelatonUn::HitCollection]
      def isobib_search_filter(code)
        result = search(code)
        result.select { |i| i.hit[:symbol].include? code }.first
      end
    end
  end
end
