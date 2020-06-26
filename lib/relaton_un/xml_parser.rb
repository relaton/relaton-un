module RelatonUn
  class XMLParser < RelatonBib::XMLParser
    class << self
      private

      # @param item_hash [Hash]
      # @return [RelatonBib::BibliographicItem]
      def bib_item(item_hash)
        UnBibliographicItem.new item_hash
      end

      # @param item [Nokogiri::XML::Element]
      # @return [Hash]
      def item_data(item)
        data = super
        data[:session] = fetch_session item
        data[:distribution] = item.at("distribution")&.text
        data
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength

      # @param item [Nokogiri::XML::Element]
      # @return [RelatonUn::Session]
      def fetch_session(item)
        session = item.at "./ext/session"
        return unless session

        RelatonUn::Session.new(
          session_number: session.at("number")&.text,
          session_date: session.at("session-date")&.text,
          item_number: session.xpath("item-number").map(&:text),
          item_name: session.xpath("item-name").map(&:text),
          subitem_name: session.xpath("subitem-name").map(&:text),
          collaboration: session.at("collaboration")&.text,
          agenda_id: session.at("agenda-id")&.text,
          item_footnote: session.at("item-footnote")&.text,
        )
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      # @param ext [Nokogiri::XML::Element]
      # @return [RelatonUn::EditorialGroup]
      def fetch_editorialgroup(ext)
        eg = ext.at("./editorialgroup")
        return unless eg

        committee = eg&.xpath("committee")&.map &:text
        EditorialGroup.new committee
      end
    end
  end
end
