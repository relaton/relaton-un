module RelatonUn
  class XMLParser < RelatonBib::XMLParser
    class << self
      def from_xml(xml)
        doc = Nokogiri::XML xml
        doc.remove_namespaces!
        titem = doc.at("/bibitem|/bibdata")
        if titem
          UnBibliographicItem.new(item_data(titem))
        else
          warn "[relaton-un] can't find bibitem or bibdata element in the XML"
        end
      end
    end
  end
end
