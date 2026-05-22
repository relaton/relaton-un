module Relaton
  module Un
    class Bibitem < Item
      model ItemData
      include Bib::BibitemShared
    end
  end
end
