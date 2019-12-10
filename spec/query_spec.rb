RSpec.describe Airbrake::Query do
  describe "#stash" do
    subject do
      described_class.new(
        method: 'GET', route: '/', query: '', start_time: Time.now,
      )
    end

    it { is_expected.to respond_to(:stash) }
  end
end
