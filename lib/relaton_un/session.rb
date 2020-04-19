module RelatonUn
  class Session
    include RelatonBib

    # @return [String, NilClass]
    attr_reader :session_number, :collaboration, :agenda_id, :item_footnote

    # @return [Date, NilClass]
    attr_reader :session_date

    # @return [Array<String>]
    attr_reader :item_number, :item_name, :subitem_name

    # @param session_number [String]
    # @param session_date [String]
    # @param item_number [Array<String>]
    # @pqrqm item_name [Array<String>]
    # @pqrqm subitem_name [Array<String>]
    # @param collaboration [String]
    # @param agenda_id [String]
    # @param item_footnote [String]
    def initialize(**args)
      @session_number = args[:session_number]
      @session_date = Date.parse args[:session_date] if args[:session_date]
      @item_number = args.fetch(:item_number, [])
      @item_name = args.fetch(:item_name, [])
      @subitem_name = args.fetch(:subitem_name, [])
      @collaboration = args[:collaboration]
      @agenda_id = args[:agenda_id]
      @item_footnote = args[:item_footnote]
    end

    # rubocop:disable Metrics/AbcSize

    # @param [Nokogiri::XML::Builder]
    def to_xml(builder)
      builder.session do |b|
        b.number session_number if session_number
        b.send "session-date", session_date.to_s if session_date
        item_number.each { |n| b.send "item-number", n }
        item_name.each { |n| b.send "item-name", n }
        subitem_name.each { |n| b.send "subitem-name", n }
        b.collaboration collaboration if collaboration
        b.send "agenda-id", agenda_id if agenda_id
        b.send "item-footnote", item_footnote if item_footnote
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    # @return [Hash]
    def to_hash
      hash = {}
      hash["session_number"] = session_number if session_number
      hash["session_date"] = session_date.to_s if session_date
      hash["item_number"] = single_element_array(item_number) if item_number.any?
      hash["item_name"] = single_element_array(item_name) if item_name.any?
      hash["subitem_name"] = single_element_array(subitem_name) if subitem_name.any?
      hash["collaboration"] = collaboration if collaboration
      hash["agenda_id"] = agenda_id if agenda_id
      hash["item_footnote"] = item_footnote if item_footnote
      hash
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  end
end
