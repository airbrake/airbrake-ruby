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
    let(:stdout) { StringIO.new }

    let(:config) do
      Airbrake::Config.new(
        project_id: 1,
        project_key: 'banana',
        logger: Logger.new(stdout)
      )
    end

    let(:sender) { described_class.new(config) }
    let(:notice) { Airbrake::Notice.new(config, AirbrakeTestError.new) }
    let(:endpoint) { 'https://airbrake.io/api/v3/projects/1/notices' }

    before { stub_request(:post, endpoint).to_return(body: '{}') }

    it "sets the Content-Type header to JSON" do
      sender.send(notice, promise)
      expect(
        a_request(:post, endpoint).with(
          headers: { 'Content-Type' => 'application/json' }
        )
      ).to have_been_made.once
    end

    it "sets the User-Agent header to the notifier slug" do
      sender.send(notice, promise)
      expect(
        a_request(:post, endpoint).with(
          headers: {
            'User-Agent' => %r{airbrake-ruby/\d+\.\d+\.\d+ Ruby/\d+\.\d+\.\d+}
          }
        )
      ).to have_been_made.once
    end

    it "sets the Authorization header to the project key" do
      sender.send(notice, promise)
      expect(
        a_request(:post, endpoint).with(
          headers: { 'Authorization' => 'Bearer banana' }
        )
      ).to have_been_made.once
    end

    it "catches exceptions raised while sending" do
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

        notice = Airbrake::Notice.new(config, ex)

        expect(sender.send(notice, promise)).to be_an(Airbrake::Promise)
        expect(promise.value).
          to match('error' => '**Airbrake: notice was not sent because of missing body')
        expect(stdout.string).to match(/ERROR -- : .+ notice was not sent/)
      end
    end

    context "when IP is rate limited" do
      let(:endpoint) { %r{https://airbrake.io/api/v3/projects/1/notices} }

      before do
        stub_request(:post, endpoint).to_return(
          status: 429,
          body: '{"message":"IP is rate limited"}',
          headers: { 'X-RateLimit-Delay' => '1' }
        )
      end

      it "returns error" do
        p1 = Airbrake::Promise.new
        sender.send(notice, p1)
        expect(p1.value).to match('error' => '**Airbrake: IP is rate limited')

        p2 = Airbrake::Promise.new
        sender.send(notice, p2)
        expect(p2.value).to match('error' => '**Airbrake: IP is rate limited')

        # Wait for X-RateLimit-Delay and then make a new request to make sure p2
        # was ignored (no request made for it).
        sleep 1

        p3 = Airbrake::Promise.new
        sender.send(notice, p3)
        expect(p3.value).to match('error' => '**Airbrake: IP is rate limited')

        expect(a_request(:post, endpoint)).to have_been_made.twice
      end
    end
  end
end
