RSpec.describe Airbrake::Stat do
  subject(:stat) { described_class.new }

  describe "#to_h" do
    it "converts to a hash" do
      expect(stat.to_h).to eq(
        'count' => 0,
        'sum' => 0.0,
        'sumsq' => 0.0,
        'tdigest' => 'AAAAAkA0AAAAAAAAAAAAAA==',
      )
    end
  end

  describe "#increment_ms" do
    before { stat.increment_ms(1000) }

    its(:sum) { is_expected.to eq(1000) }
    its(:sumsq) { is_expected.to eq(1000000) }

    it "updates tdigest" do
      expect(stat.tdigest.size).to eq(1)
    end
  end

  describe "#inspect" do
    it "provides custom inspect output" do
      expect(stat.inspect).to eq(
        '#<struct Airbrake::Stat count=0, sum=0.0, sumsq=0.0>',
      )
    end
  end

  describe "#pretty_print" do
    it "is an alias of #inspect" do
      expect(stat.method(:pretty_print)).to eql(stat.method(:inspect))
    end
  end
end
