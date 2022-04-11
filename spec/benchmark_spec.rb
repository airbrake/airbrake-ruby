RSpec.describe Airbrake::Benchmark do
  subject(:benchmark) { described_class.new }

  describe ".measure" do
    it "returns measured performance time" do
      expect(described_class.measure { '10' * 10 }).to be_kind_of(Numeric)
    end
  end

  describe "#stop" do
    before { benchmark }

    context "when called one time" do
      its(:stop) { is_expected.to be(true) }
    end

    context "when called twice or more" do
      before { benchmark.stop }

      its(:stop) { is_expected.to be(false) }
    end
  end

  describe "#duration" do
    context "when #stop wasn't called yet" do
      its(:duration) { is_expected.to be_zero }
    end

    context "when #stop was called" do
      before { benchmark.stop }

      its(:duration) { is_expected.to be > 0 }
    end
  end
end
