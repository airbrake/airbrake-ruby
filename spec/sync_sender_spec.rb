RSpec.describe Airbrake::SyncSender do
  subject(:sync_sender) { described_class.new }

  let(:mock_backlog) { instance_double(Airbrake::Backlog) }

  before do
    Airbrake::Config.instance = Airbrake::Config.new(
      project_id: 1, project_key: 'banana',
    )
    allow(Airbrake::Backlog).to receive(:new).and_return(mock_backlog)
  end

  describe "#send" do
    let(:promise) { Airbrake::Promise.new }

    let(:notice) { Airbrake::Notice.new(AirbrakeTestError.new) }
    let(:endpoint) { 'https://api.airbrake.io/api/v3/projects/1/notices' }

    before { stub_request(:post, endpoint).to_return(body: '{}') }

    it "sets the Content-Type header to JSON" do
      sync_sender.send({}, promise)
      expect(
        a_request(:post, endpoint).with(
          headers: { 'Content-Type' => 'application/json' },
        ),
      ).to have_been_made.once
    end

    it "sets the User-Agent header to the notifier slug" do
      sync_sender.send({}, promise)
      expect(
        a_request(:post, endpoint).with(
          headers: {
            'User-Agent' => %r{
              airbrake-ruby/\d+\.\d+\.\d+(\.rc\.\d+)?\sRuby/\d+\.\d+\.\d+
            }x,
          },
        ),
      ).to have_been_made.once
    end

    it "sets the Authorization header to the project key" do
      sync_sender.send({}, promise)
      expect(
        a_request(:post, endpoint).with(
          headers: { 'Authorization' => 'Bearer banana' },
        ),
      ).to have_been_made.once
    end

    it "catches exceptions raised while sending" do
      # rubocop:disable RSpec/VerifiedDoubles
      https = double("foo")
      # rubocop:enable RSpec/VerifiedDoubles

      # rubocop:disable RSpec/SubjectStub
      allow(sync_sender).to receive(:build_https).and_return(https)
      # rubocop:enable RSpec/SubjectStub

      allow(https).to receive(:request).and_raise(StandardError.new('foo'))

      expect(sync_sender.send({}, promise)).to be_an(Airbrake::Promise)
      expect(promise.value).to eq('error' => '**Airbrake: HTTP error: foo')
    end

    it "logs exceptions raised while sending" do
      allow(Airbrake::Loggable.instance).to receive(:error)

      # rubocop:disable RSpec/VerifiedDoubles
      https = double("foo")
      # rubocop:enable RSpec/VerifiedDoubles

      # rubocop:disable RSpec/SubjectStub
      allow(sync_sender).to receive(:build_https).and_return(https)
      # rubocop:enable RSpec/SubjectStub

      allow(https).to receive(:request).and_raise(StandardError.new('foo'))

      sync_sender.send({}, promise)

      expect(Airbrake::Loggable.instance).to have_received(:error).with(
        /HTTP error: foo/,
      )
    end

    context "when request body is nil" do
      # rubocop:disable RSpec/MultipleExpectations
      it "doesn't send data" do
        allow(Airbrake::Loggable.instance).to receive(:error)

        allow_any_instance_of(Airbrake::Truncator)
          .to receive(:reduce_max_size).and_return(0)

        encoded = Base64.encode64("\xD3\xE6\xBC\x9D\xBA").encode!('ASCII-8BIT')
        bad_string = Base64.decode64(encoded)

        ex = AirbrakeTestError.new
        backtrace = []
        10.times { backtrace << "bin/rails:3:in `<#{bad_string}>'" }
        ex.set_backtrace(backtrace)

        notice = Airbrake::Notice.new(ex)

        expect(sync_sender.send(notice, promise)).to be_an(Airbrake::Promise)
        expect(promise.value)
          .to match('error' => '**Airbrake: data was not sent because of missing body')

        expect(Airbrake::Loggable.instance).to have_received(:error).with(
          /data was not sent/,
        )
        expect(Airbrake::Loggable.instance).to have_received(:error).with(
          /truncation failed/,
        )
      end
      # rubocop:enable RSpec/MultipleExpectations
    end

    context "when IP is rate limited" do
      let(:endpoint) { %r{https://api.airbrake.io/api/v3/projects/1/notices} }

      before do
        stub_request(:post, endpoint).to_return(
          status: 429,
          body: '{"message":"IP is rate limited"}',
          headers: { 'X-RateLimit-Delay' => '1' },
        )
        allow(mock_backlog).to receive(:<<)
      end

      # rubocop:disable RSpec/MultipleExpectations
      it "returns error" do
        p1 = Airbrake::Promise.new
        sync_sender.send({}, p1)
        expect(p1.value).to match('error' => '**Airbrake: IP is rate limited')

        p2 = Airbrake::Promise.new
        sync_sender.send({}, p2)
        expect(p2.value).to match('error' => '**Airbrake: IP is rate limited')

        # Wait for X-RateLimit-Delay and then make a new request to make sure p2
        # was ignored (no request made for it).
        sleep 1

        p3 = Airbrake::Promise.new
        sync_sender.send({}, p3)
        expect(p3.value).to match('error' => '**Airbrake: IP is rate limited')

        expect(a_request(:post, endpoint)).to have_been_made.twice
      end
      # rubocop:enable RSpec/MultipleExpectations
    end

    context "when the provided method is :put" do
      before { stub_request(:put, endpoint).to_return(status: 200, body: '') }

      it "PUTs the request" do
        sender = described_class.new(:put)
        sender.send({}, promise)
        expect(a_request(:put, endpoint)).to have_been_made
      end
    end

    context "when the provided method is :post" do
      it "POSTs the request" do
        sender = described_class.new(:post)
        sender.send({}, promise)
        expect(a_request(:post, endpoint)).to have_been_made
      end
    end

    described_class::BACKLOGGABLE_STATUS_CODES.each do |status_code|
      context "when the response code is backloggable" do
        before do
          allow(mock_backlog).to receive(:<<)
          allow(Airbrake::Response).to receive(:parse).and_return('code' => status_code)
        end

        it "sends the data to the backlog when the response is #{status_code}" do
          described_class.new(:post).send(1, promise)
          allow(mock_backlog).to receive(:<<).with(1)
        end
      end
    end

    context "when the response code is not backloggable" do
      before do
        allow(mock_backlog).to receive(:<<)
        allow(Airbrake::Response).to receive(:parse).and_return('code' => 999)
      end

      it "doesn't send the data to the backlog" do
        described_class.new(:post).send(1, promise)
        expect(mock_backlog).not_to have_received(:<<)
      end
    end
  end

  describe "#close" do
    before { allow(mock_backlog).to receive(:close) }

    it "closes the backlog" do
      sync_sender.close
      expect(mock_backlog).to have_received(:close)
    end
  end
end
