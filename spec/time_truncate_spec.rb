require 'spec_helper'

RSpec.describe Airbrake::TimeTruncate do
  describe "#utc_truncate_minutes" do
    it "truncates time to the floor minute and returns an RFC3339 timestamp" do
      time = Time.new(2018, 1, 1, 0, 0, 20, 0)
      expect(subject.utc_truncate_minutes(time)).to eq('2018-01-01T00:00:00+00:00')
    end
  end
end
