RSpec.describe RelatonUn::UnBibliographicItem do
  it "warn if distribution is invalid" do
    expect do
      RelatonUn::UnBibliographicItem.new distribution: "INV"
    end.to output(/\[relaton-un\] WARN: Invalid distribution: `INV`/).to_stderr_from_any_process
  end

  it "return AsciiBib" do
    hash = YAML.load_file "spec/fixtures/un_bib.yaml"
    hash_bib = RelatonUn::HashConverter.hash_to_bib hash
    item = RelatonUn::UnBibliographicItem.new(**hash_bib)
    bib = item.to_asciibib
    file = "spec/fixtures/asciibib.adoc"
    File.write file, bib, encoding: "UTF-8" unless File.exist? file
    expect(bib).to eq File.read(file, encoding: "UTF-8")
  end
end
