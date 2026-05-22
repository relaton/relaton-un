module Relaton
  module Un
    class Doctype < Bib::Doctype
      attribute :content, :string, values: %w[
        recommendation plenary addendum communication corrigendum
        reissue agenda budgetary sec-gen-notes expert-report resolution
      ]
    end
  end
end
