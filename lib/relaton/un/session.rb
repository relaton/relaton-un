module Relaton
  module Un
    class Session < Lutaml::Model::Serializable
      attribute :number, :string
      attribute :session_date, :date
      attribute :item_number, :string, collection: true
      attribute :item_name, :string, collection: true
      attribute :subitem_name, :string, collection: true
      attribute :collaborator, :string
      attribute :agenda_id, :string
      attribute :item_footnote, :string

      xml do
        map_element "number", to: :number
        map_element "session-date", to: :session_date
        map_element "item-number", to: :item_number
        map_element "item-name", to: :item_name
        map_element "subitem-name", to: :subitem_name
        map_element "collaborator", to: :collaborator
        map_element "agenda-id", to: :agenda_id
        map_element "item-footnote", to: :item_footnote
      end
    end
  end
end
