RSpec.describe RelatonUn::UnBibliographicItem do
  it "warn if distribution is invalid" do
    expect do
      RelatonUn::UnBibliographicItem.new distribution: "INV"
    end.to output(/invalid distribution/).to_stderr
  end
end
