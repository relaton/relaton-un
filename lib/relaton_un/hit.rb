# frozen_string_literal: true

module RelatonUn
  # Hit.
  class Hit < RelatonBib::Hit
    # rubocop:disable Layout/LineLength

    # There is distribution PRO (A/47/PV.102/CORR.1, A/47/PV.54)
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
      "AMCOW" => "African Ministers’ Council on Water",
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
    # @return [RelatonUn::UnBibliographicItem]
    def fetch
      @fetch ||= un_bib_item
    end

    private

    # rubocop:disable Metrics/MethodLength

    # @return [RelatonUn::UnBibliographicItem]
    def un_bib_item # rubocop:disable Metrics/AbcSize
      UnBibliographicItem.new(
        type: "standard",
        fetched: Date.today.to_s,
        docid: fetch_docid,
        docnumber: hit[:ref],
        language: ["en"],
        script: ["Latn"],
        title: fetch_title,
        date: fetch_date,
        link: fetch_link,
        keyword: fetch_keyword,
        session: fetch_session,
        distribution: fetch_distribution,
        editorialgroup: fetch_editorialgroup,
        classification: fetch_classification,
        job_number: hit[:job_number],
      )
    end
    # rubocop:enable Metrics/MethodLength

    # @return [Array<RelatonBib::DocumentIdentifier>]
    def fetch_docid
      dids = hit[:symbol].map do |s|
        RelatonBib::DocumentIdentifier.new(id: s, type: "UN")
      end
      dids.first.instance_variable_set :@primary, true
      dids
    end

    # @return [Array<RelatonBib::TypedTitleString>]
    def fetch_title
      RelatonBib::TypedTitleString.from_string hit[:title], "en", "Latn"
    end

    # @return [Array<RelatonBib::BibliographicDate>]
    def fetch_date
      d = []
      d << bibdate("published", hit[:date_pub]) if hit[:date_pub]
      d << bibdate("issued", hit[:date_rel]) if hit[:date_rel]
      d
    end

    # @param type [String]
    # @param on [String]
    # @return [RelatonBib::BibliographicDate]
    def bibdate(type, on)
      RelatonBib::BibliographicDate.new type: type, on: on
    end

    # @return [Array<RelatonBib::TypedUri>]
    def fetch_link
      hit[:link].map { |l| RelatonBib::TypedUri.new(**l) }
    end

    # @return [Array<String>]
    def fetch_keyword
      hit[:keyword].split(", ")
    end

    # @return [RelatonUn::Session]
    def fetch_session
      Session.new(session_number: hit[:session], agenda_id: hit[:agenda])
    end

    # @return [String]
    def fetch_distribution
      UnBibliographicItem::DISTRIBUTIONS[hit[:distribution]]
    end

    # @return [RelatonUn::EditorialGroup, NilClass]
    def fetch_editorialgroup # rubocop:disable Metrics/AbcSize
      tc = hit[:ref].match(/^\S+/).to_s.split(/\/|-/).reduce([]) do |m, v|
        if BODY[v] then m << BODY[v]
        elsif v.match?(/(AC|C|CN|CONF|GC|SC|Sub|WG).\d+|PC/) then m << v
        else m
        end
      end.uniq
      return unless tc.any?

      RelatonUn::EditorialGroup.new tc
    end

    # @return [Array<RelatonBib::Classification>]
    def fetch_classification
      [RelatonBib::Classification.new(type: "area", value: "UNDOC")]
    end
  end
end
