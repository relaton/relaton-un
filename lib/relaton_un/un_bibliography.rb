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
             Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError,
             OpenSSL::SSL::SSLError, Errno::ETIMEDOUT
        raise RelatonBib::RequestError, "Could not access #{HitCollection::DOMAIN}"
      end

      # @param ref [String] document reference
      # @param year [String, NilClass]
      # @param opts [Hash] options
      # @return [RelatonUn::UnBibliographicItem]
      def get(ref, _year = nil, _opts = {})
        warn "[relaton-un] (\"#{ref}\") fetching..."
        result = isobib_search_filter(ref)
        if result
          warn "[relaton-un] (\"#{ref}\") found #{result.fetch.docidentifier.first.id}"
          result.fetch
        end
      end

      private

      # Search for hits.
      #
      # @param ref [String] reference without correction
      # @return [RelatonUn::HitCollection]
      def isobib_search_filter(ref)
        result = search(ref)
        result.select { |i| i.hit[:ref] == ref }.first
      end
    end
  end
end
