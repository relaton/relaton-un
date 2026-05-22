require "relaton/un/processor"

describe Relaton::Un::Processor do
  subject(:processor) { described_class.new }

  it "initializes with correct attributes" do
    expect(processor.short).to eq :relaton_un
    expect(processor.prefix).to eq "UN"
    expect(processor.defaultprefix).to eq(%r{^UN\s})
    expect(processor.idtype).to eq "UN"
  end

  describe "#get" do
    it "delegates to Bibliography.get" do
      expect(Relaton::Un::Bibliography).to receive(:get).with("code", "date", {}).and_return(:result)
      expect(processor.get("code", "date", {})).to eq :result
    end
  end

  describe "#from_xml" do
    it "delegates to Bibdata.from_xml" do
      xml = File.read("spec/fixtures/bibdata.xml", encoding: "UTF-8")
      expect(Relaton::Un::Bibdata).to receive(:from_xml).with(xml).and_return(:bibdata)
      expect(processor.from_xml(xml)).to eq :bibdata
    end
  end

  describe "#from_yaml" do
    it "delegates to Item.from_yaml" do
      yaml = File.read("spec/fixtures/item.yaml", encoding: "UTF-8")
      expect(Relaton::Un::Item).to receive(:from_yaml).with(yaml).and_return(:item)
      expect(processor.from_yaml(yaml)).to eq :item
    end
  end

  describe "#grammar_hash" do
    it "delegates to Relaton::Un.grammar_hash" do
      expect(Relaton::Un).to receive(:grammar_hash).and_return("hash")
      expect(processor.grammar_hash).to eq "hash"
    end
  end
end
