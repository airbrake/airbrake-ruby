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

  describe "#send" do
    it "catches exceptions raised when sending" do
      stdout = StringIO.new
      config = Airbrake::Config.new(logger: Logger.new(stdout))
      sender = described_class.new config
      notice = Airbrake::Notice.new(config, AirbrakeTestError.new)
      https = double("foo")
      allow(sender).to receive(:build_https).and_return(https)
      allow(https).to receive(:request).and_raise(StandardError.new('foo'))
      expect(sender.send(notice)).to be_nil
      expect(stdout.string).to match(/ERROR -- : .+ HTTP error: foo/)
    end
  end
end
