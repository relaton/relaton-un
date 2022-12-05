RSpec.describe RelatonUn::HashConverter do
  it "create bibitem form HASH" do
    hash = YAML.load_file "spec/fixtures/un_bib.yaml"
    hash_bib = RelatonUn::HashConverter.hash_to_bib hash
    item = RelatonUn::UnBibliographicItem.new(**hash_bib)
    expect(item.to_hash).to eq hash
    file = "spec/fixtures/un_bib.xml"
    xml = item.to_xml bibdata: true
    File.write file, xml, encoding: "UTF-8" unless File.exist? file
    expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
    schema = Jing.new "grammars/relaton-un-compile.rng"
    errors = schema.validate file
    expect(errors).to eq []
  end
end
