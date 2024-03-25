module RelatonUn
  class DocumentType < RelatonBib::DocumentType
    DOCTYPES = %w[
      recommendation plenary addendum communication corrigendum reissue agenda
      budgetary sec-gen-notes expert-report resolution
    ].freeze

    def initialize(type:, abbreviation: nil)
      check_type type
      super
    end

    def check_type(type)
      unless DOCTYPES.include? type
        Util.warn "invalid doctype: `#{type}`"
      end
    end
  end
end
