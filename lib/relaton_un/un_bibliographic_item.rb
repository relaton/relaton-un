module RelatonUn
  class UnBibliographicItem < RelatonBib::BibliographicItem
    TYPES = %w[
      recommendation plenary addendum communication corrigendum reissue agenda
      budgetary sec-gen-notes expert-report resolution
    ].freeze
  end
end
