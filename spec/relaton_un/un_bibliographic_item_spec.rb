RSpec.describe RelatonUn::UnBibliographicItem do
  it "warn if distribution is invalid" do
    expect do
      RelatonUn::UnBibliographicItem.new distribution: "INV"
    end.to output(/invalid distribution/).to_stderr
  end

  it "return AsciiBib" do
    hash = YAML.load_file "spec/fixtures/un_bib.yaml"
    hash_bib = RelatonUn::HashConverter.hash_to_bib hash
    item = RelatonUn::UnBibliographicItem.new **hash_bib
    bib = item.to_asciibib
    file = "spec/fixtures/asciibib.adoc"
    File.write file, bib, encoding: "UTF-8" unless File.exist? file
    expect(bib).to eq File.read(file, encoding: "UTF-8")
      .gsub(/(?<=fetched::\s)\d[4]-\d{2}-\n{2}/, Date.today.to_s)
  end
end
