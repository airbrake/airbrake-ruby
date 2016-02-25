require 'spec_helper'

RSpec.describe Airbrake::SyncSender do
  describe "#build_https" do
    it "overrides Net::HTTP's open_timeout and read_timeout if timeout is specified" do
      config = Airbrake::Config.new(timeout: 10)
      sender = described_class.new(config)
      https = sender.__send__(:build_https, config.endpoint)
      expect(https.open_timeout).to eq(10)
      expect(https.read_timeout).to eq(10)
    end
  end
end
