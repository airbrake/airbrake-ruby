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
    let(:promise) { Airbrake::Promise.new }

    it "catches exceptions raised while sending" do
      stdout = StringIO.new
      config = Airbrake::Config.new(logger: Logger.new(stdout))
      sender = described_class.new(config)
      notice = Airbrake::Notice.new(config, AirbrakeTestError.new)
      https = double("foo")
      allow(sender).to receive(:build_https).and_return(https)
      allow(https).to receive(:request).and_raise(StandardError.new('foo'))
      expect(sender.send(notice, promise)).to be_an(Airbrake::Promise)
      expect(promise.value).to eq('error' => '**Airbrake: HTTP error: foo')
      expect(stdout.string).to match(/ERROR -- : .+ HTTP error: foo/)
    end

    context "when request body is nil" do
      it "doesn't send a notice" do
        expect_any_instance_of(Airbrake::Truncator).
          to receive(:reduce_max_size).and_return(0)

        encoded = Base64.encode64("\xD3\xE6\xBC\x9D\xBA").encode!('ASCII-8BIT')
        bad_string = Base64.decode64(encoded)

        ex = AirbrakeTestError.new
        backtrace = []
        10.times { backtrace << "bin/rails:3:in `<#{bad_string}>'" }
        ex.set_backtrace(backtrace)

        stdout = StringIO.new
        config = Airbrake::Config.new(logger: Logger.new(stdout))

        sender = described_class.new(config)
        notice = Airbrake::Notice.new(config, ex)

        expect(sender.send(notice, promise)).to be_an(Airbrake::Promise)
        expect(promise.value).
          to match('error' => '**Airbrake: notice was not sent because of missing body')
        expect(stdout.string).to match(/ERROR -- : .+ notice was not sent/)
      end
    end
  end
end
