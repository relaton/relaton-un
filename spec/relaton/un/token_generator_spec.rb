require "relaton/un/token_generator"
require "yaml"

describe Relaton::Un::TokenGenerator do
  describe ".generate" do
    before do
      described_class.instance_variable_set(:@cached_token, nil)
    end

    it "returns a decimal string" do
      token = described_class.generate
      expect(token).to be_a(String)
      expect(token).to match(/\A-?\d+\z/)
    end

    it "caches the token within the same minute" do
      first = described_class.generate
      second = described_class.generate
      expect(second).to eq(first)
    end

    it "regenerates the token when the minute changes" do
      _first = described_class.generate

      future = Time.now.utc + 120
      allow(Time).to receive(:now).and_return(future)

      described_class.instance_variable_set(:@cached_token, nil)
      second = described_class.generate
      expect(second).to be_a(String)
      expect(second).to match(/\A-?\d+\z/)
    end
  end

  describe "golden tokens (interpreter vs frozen wasmtime output)" do
    vectors = YAML.load_file(File.expand_path("../../fixtures/tokens.yml", __dir__))

    vectors.each do |v|
      it "produces #{v['token']} for input #{v['input'].inspect}" do
        result = described_class.send(:call_wasm, *v["input"])
        expect(result).to eq(v["token"])
      end
    end
  end

  describe Relaton::Un::TokenGenerator::Heap do
    subject(:heap) { described_class.new }

    describe "#get" do
      it "returns :undefined for index 0" do
        expect(heap.get(0)).to eq(:undefined)
      end

      it "returns nil for index 1" do
        expect(heap.get(1)).to be_nil
      end

      it "returns true for index 2" do
        expect(heap.get(2)).to eq(true)
      end

      it "returns false for index 3" do
        expect(heap.get(3)).to eq(false)
      end
    end

    describe "#alloc and #get round-trip" do
      it "stores and retrieves an object" do
        obj = Object.new
        idx = heap.alloc(obj)
        expect(heap.get(idx)).to be(obj)
      end
    end

    describe "#drop" do
      it "reuses freed slots on next alloc" do
        # Fill slots up to BUILTINS threshold so drop will actually free
        idx = nil
        33.times { idx = heap.alloc(Object.new) }
        expect(idx).to be >= Relaton::Un::TokenGenerator::Heap::BUILTINS

        heap.drop(idx)

        obj2 = Object.new
        idx2 = heap.alloc(obj2)
        expect(idx2).to eq(idx)
        expect(heap.get(idx2)).to be(obj2)
      end

      it "does not corrupt builtins when dropping builtin indices" do
        (0...Relaton::Un::TokenGenerator::Heap::BUILTINS).each { |i| heap.drop(i) }

        expect(heap.get(0)).to eq(:undefined)
        expect(heap.get(1)).to be_nil
        expect(heap.get(2)).to eq(true)
        expect(heap.get(3)).to eq(false)
      end
    end
  end
end
