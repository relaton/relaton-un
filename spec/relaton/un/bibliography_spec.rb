# frozen_string_literal: true

describe Relaton::Un::Bibliography do
  it "raise RequestError" do
    expect(Faraday).to receive(:new).and_raise Faraday::ConnectionFailed, "test"
    expect do
      described_class.search "ref"
    end.to raise_error Relaton::RequestError
  end

  it "search a code" do
    VCR.use_cassette "trade_cefact_2004_32" do
      results = Relaton::Un::Bibliography.search "TRADE/CEFACT/2004/32"
      expect(results).to be_instance_of Relaton::Un::HitCollection
      expect(results.size).to be >= 1
      expect(results.first).to be_instance_of Relaton::Un::Hit
    end
  end

  it "get document", vcr: "trade_cefact_2004_32" do
    expect do
      result = Relaton::Un::Bibliography.get "UN TRADE/CEFACT/2004/32"
      expect(result).not_to be_nil
      expect(result.docidentifier.first.content).to eq "TRADE/CEFACT/2004/32"
    end.to output(
      include("[relaton-un] INFO: (UN TRADE/CEFACT/2004/32) Fetching from documents.un.org ...",
              "[relaton-un] INFO: (UN TRADE/CEFACT/2004/32) Found: `TRADE/CEFACT/2004/32`"),
    ).to_stderr
  end

  it "not found document", vcr: "not_found" do
    result = Relaton::Un::Bibliography.get "UN NOT/FOUND"
    expect(result).to be_nil
  end
end
