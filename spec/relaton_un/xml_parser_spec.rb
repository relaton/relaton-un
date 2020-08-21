RSpec.describe RelatonUn::XMLParser do
  it "create bibitem form XML" do
    xml = File.read "spec/fixtures/un_bib.xml", encoding: "UTF-8"
    item = RelatonUn::XMLParser.from_xml xml
    expect(item.to_xml(bibdata: true)).to be_equivalent_to xml
  end

  it "warn if XML doesn't contein bibiten or bibdata" do
    expect { RelatonUn::XMLParser.from_xml "" }.to output(/can't find bibitem/)
      .to_stderr
  end
end
