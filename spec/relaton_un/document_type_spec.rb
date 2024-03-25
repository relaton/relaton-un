describe RelatonUn::DocumentType do
  it "warn if doctype is invalid" do
    expect do
      described_class.new type: "invalid"
    end.to output(/\[relaton-un\] WARN: invalid doctype: `invalid`/).to_stderr_from_any_process
  end
end
