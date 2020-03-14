# frozen_string_literal: true

module RelatonUn
  # Hit.
  class Hit < RelatonBib::Hit
    # Parse page.
    # @return [RelatonUn::UnBibliographicItem]
    def fetch
      @fetch ||= un_bib_item
    end

    private

    def un_bib_item
      UnBibliographicItem.new(
        type: "standard",
        fetched: Date.today.to_s,
        docid: docid,
        docnumber: hit[:ref],
        language: ["en"],
        script: ["Latn"],
        title: title,
        date: date,
        link: link,
        keyword: keyword
      )
    end

    # @return [Array<RelatonBib::DocumentIdentifier>]
    def docid
      [RelatonBib::DocumentIdentifier.new(id: hit[:ref], type: "UN")]
    end

    # @return [Array<RelatonBib::TypedTitleString>]
    def title
      fs = RelatonBib::FormattedString.new(content: hit[:title], language: "en", script: "Latn")
      [RelatonBib::TypedTitleString.new(type: "main", title: fs)]
    end

    # @return [Array<RelatonBib::BibliographicDate>]
    def date
      d = []
      d << RelatonBib::BibliographicDate.new(type: "published", on: hit[:date_pub]) if hit[:date_pub]
      d << RelatonBib::BibliographicDate.new(type: "issued", on: hit[:date_rel]) if hit[:date_rel]
      d
    end

    # @return [Array<RelatonBib::TypedUri>]
    def link
      hit[:link].map { |l| RelatonBib::TypedUri.new l }
    end

    # @return [Array<String>]
    def keyword
      hit[:keyword].split(", ")
    end
  end
end
