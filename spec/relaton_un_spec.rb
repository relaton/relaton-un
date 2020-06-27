RSpec.describe RelatonUn do
  it "has a version number" do
    expect(RelatonUn::VERSION).not_to be nil
  end

  it "retur grammar hash" do
    hash = RelatonUn.grammar_hash
    expect(hash).to be_instance_of String
    expect(hash.size).to eq 32
  end

  it "search a code" do
    VCR.use_cassette "trade_cefact_2004_32" do
      results = RelatonUn::UnBibliography.search "TRADE/CEFACT/2004/32"
      expect(results).to be_instance_of RelatonUn::HitCollection
      expect(results.size).to be 1
      expect(results.first).to be_instance_of RelatonUn::Hit
    end
  end

  it "raise RequestError" do
    http = double "net_http"
    expect(http).to receive(:use_ssl=)
    expect(http).to receive(:read_timeout=)
    expect(http).to receive(:request).and_raise SocketError
    expect(Net::HTTP).to receive(:new).and_return http
    expect { RelatonUn::UnBibliography.search "ref" }.to raise_error RelatonBib::RequestError
  end

  it "get document" do
    VCR.use_cassette "trade_cefact_2004_32" do
      result = RelatonUn::UnBibliography.get "UN TRADE/CEFACT/2004/32"
      expect(result).to be_instance_of RelatonUn::UnBibliographicItem
      xml = result.to_xml bibdata: true
      file = "spec/fixtures/trade_cefact_2004_32.xml"
      File.write file, xml, encoding: "UTF-8" unless File.exist? file
      expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8").
        gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
      schema = Jing.new "spec/fixtures/bibdata.rng"
      errors = schema.validate file
      expect(errors).to eq []
    end
  end

  it "get document with 2 symbols" do
    VCR.use_cassette "trade_wp_4_1068" do
      result = RelatonUn::UnBibliography.get "TRADE/WP.4/1068"
      xml = result.to_xml bibdata: true
      file = "spec/fixtures/trade_wp_4_1068.xml"
      File.write file, xml, encoding: "UTF-8" unless File.exist? file
      expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8").
        gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
    end
  end
end
