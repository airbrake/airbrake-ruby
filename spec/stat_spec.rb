require 'spec_helper'

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
    let(:end_time) { Time.new(2018, 1, 1, 0, 0, 21, 0) }

    before { subject.increment(start_time, end_time) }

    it "increments count" do
      expect(subject.count).to eq(1)
    end

    it "updates sum" do
      expect(subject.sum).to eq(1000)
    end

    it "updates sumsq" do
      expect(subject.sumsq).to eq(1000000)
    end

    it "updates tdigest" do
      expect(subject.tdigest.size).to eq(1)
    end
  end
end
