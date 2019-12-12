RSpec.describe Airbrake::Query do
  describe "#stash" do
    subject do
      described_class.new(
        method: 'GET', route: '/', query: '', start_time: Time.now,
      )
    end

    it { is_expected.to respond_to(:stash) }
  end

  describe "#end_time" do
    it "is always equal to start_time + 1 second by default" do
      time = Time.now
      query = described_class.new(
        method: 'GET', route: '/', query: '', start_time: time,
      )
      expect(query.end_time).to eq(time + 1)
    end
  end
end
