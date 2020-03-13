RSpec.describe RelatonUn::HashConverter do
  it "create bibitem form HASH" do
    hash = YAML.load_file "spec/fixtures/un_bib.yaml"
    hash_bib = RelatonUn::HashConverter.hash_to_bib hash
    item = RelatonUn::UnBibliographicItem.new hash_bib
    expect(item.to_hash).to eq hash
  end
end
