# frozen_string_literal: true

module Relaton
  module Un
    class Hit < Core::Hit
      # rubocop:disable Layout/LineLength
      BODY = {
        "A" => "General Assembly",
        "E" => "Economic and Social Council",
        "S" => "Security Council",
        "T" => "Trusteeship Council",
        "ACC" => "Administrative Committee on Coordination",
        "AT" => "United Nations Administrative Tribunal",
        "CAT" => "Committee against Torture",
        "CCPR" => "Human Rights Committee",
        "CD" => "Conference on Disarmament",
        "CEDAW" => "Committee on the Elimination of All Forms of Discrimination against Women",
        "CERD" => "Committee on the Elimination of Racial Discrimination",
        "CRC" => "Committee on the Rights of the Child",
        "DC" => "Disarmament Commission",
        "DP" => "United Nations Development Programme",
        "HS" => "United Nations Centre for Human Settlements (HABITAT)",
        "TD" => "United Nations Conference on Trade and Development",
        "UNEP" => "United Nations Environment Programme",
        "TRADE" => "Committee on Trade",
        "CEFACT" => "Centre for Trade Facilitation and Electronic Business",
        "C.1" => "Disarmament and International Security Committee",
        "C.2" => "Economic and Financial Committee",
        "C.3" => "Social, Humanitarian & Cultural Issues",
        "C.4" => "Special Political and Decolonization Committee",
        "C.5" => "Administrative and Budgetary Committee",
        "C.6" => "Sixth Committee (Legal)",
        "PC" => "Preparatory Committee",
        "AEC" => "Atomic Energy Commission",
        "AGRI" => "Committee on Agriculture",
        "AMCEN" => "African Ministerial Conference on the Environment",
        "AMCOW" => "African Ministers' Council on Water",
        "ECA" => "Economic Commission for Africa",
        "ESCAP" => "Economic and Social Commission for Asia and Pacific",
        "ECE" => "Economic Commission for Europe",
        "ECWA" => "Economic Commission for Western Asia",
        "UNFF" => "United Nations Forum on Forests",
        "ENERGY" => "Committee on Sustainable Energy",
        "FAO" => "Food and Agriculture Organization",
        "UNCTAD" => "United Nations Conference on Trade and Development",
      }.freeze
      # rubocop:enable Layout/LineLength

      # Parse page.
      # @return [Relaton::Un::Item]
      def item
        @item ||= Parser.new(hit).parse
      end
    end
  end
end
