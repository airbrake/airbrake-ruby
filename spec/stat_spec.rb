RSpec.describe Airbrake::Stat do
  describe "#to_h" do
    it "converts to a hash" do
      expect(subject.to_h).to eq(
        'count' => 0,
        'sum' => 0.0,
        'sumsq' => 0.0,
        'tdigest' => 'AAAAAkA0AAAAAAAAAAAAAA=='
      )
    end
  end

  describe "#increment" do
    let(:start_time) { Time.new(2018, 1, 1, 0, 0, 20, 0) }
    let(:end_time) { Time.new(2018, 1, 1, 0, 0, 22, 0) }

    before { subject.increment(start_time, end_time) }

    its(:sum) { is_expected.to eq(2000) }
  end

  describe "#increment_ms" do
    before { subject.increment_ms(1000) }

    its(:count) { is_expected.to eq(1) }
    its(:sum) { is_expected.to eq(1000) }
    its(:sumsq) { is_expected.to eq(1000000) }

    it "updates tdigest" do
      expect(subject.tdigest.size).to eq(1)
    end
  end
end
