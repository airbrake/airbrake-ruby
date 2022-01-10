RSpec.describe Airbrake::TimeTruncate do
  time = Time.new(2018, 1, 1, 0, 0, 20, 0)
  time_with_zone = Time.new(2018, 1, 1, 0, 0, 20, '-05:00')

  describe "#utc_truncate_minutes" do
    shared_examples 'time conversion' do |t|
      it "truncates the time to the floor minute and returns an RFC3339 timestamp" do
        expect(described_class.utc_truncate_minutes(t))
          .to eq('2018-01-01T00:00:00+00:00')
      end

      it "converts time with zone to UTC" do
        expect(described_class.utc_truncate_minutes(time_with_zone))
          .to eq('2018-01-01T05:00:00+00:00')
      end
    end

    context "when the time argument is a Time object" do
      include_examples 'time conversion', time
    end

    context "when the time argument is a Float" do
      include_examples 'time conversion', time.to_f
    end

    context "when the time argument is an Integer" do
      include_examples 'time conversion', time.to_i
    end
  end
end
