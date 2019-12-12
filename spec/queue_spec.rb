RSpec.describe Airbrake::Queue do
  subject { described_class.new(queue: 'bananas', error_count: 0) }

  describe "#ignore" do
    it { is_expected.to respond_to(:ignore!) }
  end

  describe "#stash" do
    it { is_expected.to respond_to(:stash) }
  end

  describe "#end_time" do
    it "is always equal to start_time + 1 second by default" do
      time = Time.now
      queue = described_class.new(
        queue: 'bananas', error_count: 0, start_time: time,
      )
      expect(queue.end_time).to eq(time + 1)
    end
  end
end
