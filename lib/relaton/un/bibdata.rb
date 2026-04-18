module Relaton
  module Un
    class Bibdata < Item
      model ItemData
      include Bib::BibdataShared
    end
  end
end
