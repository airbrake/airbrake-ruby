RSpec.describe Airbrake::Response do
  describe ".parse" do
    [200, 201, 204].each do |code|
      context "when response code is #{code}" do
        before do
          allow(Airbrake::Loggable.instance).to receive(:debug)
        end

        it "logs response body" do
          described_class.parse(OpenStruct.new(code: code, body: '{}'))

          expect(Airbrake::Loggable.instance).to have_received(:debug).with(
            /Airbrake::Response \(#{code}\): {}/,
          )
        end
      end
    end

    [400, 401, 403, 420].each do |code|
      context "when response code is #{code}" do
        before do
          allow(Airbrake::Loggable.instance).to receive(:error)
        end

        it "logs response message" do
          described_class.parse(
            OpenStruct.new(code: code, body: '{"message":"foo"}'),
          )

          expect(Airbrake::Loggable.instance).to have_received(:error).with(
            /Airbrake: foo/,
          )
        end
      end
    end

    context "when response code is 429" do
      let(:response) { OpenStruct.new(code: 429, body: '{"message":"rate limited"}') }

      before do
        allow(Airbrake::Loggable.instance).to receive(:error)
      end

      it "logs response message" do
        described_class.parse(response)
        expect(Airbrake::Loggable.instance).to have_received(:error).with(
          /Airbrake: rate limited/,
        )
      end

      it "returns an error response" do
        time = Time.now
        allow(Time).to receive(:now).and_return(time)

        resp = described_class.parse(response)
        expect(resp).to include(
          'error' => '**Airbrake: rate limited',
          'rate_limit_reset' => time,
        )
      end
    end

    context "when response code is unhandled" do
      let(:response) { OpenStruct.new(code: 500, body: 'foo') }

      before do
        allow(Airbrake::Loggable.instance).to receive(:error)
      end

      it "logs response body" do
        described_class.parse(response)
        expect(Airbrake::Loggable.instance).to have_received(:error).with(
          /Airbrake: unexpected code \(500\)\. Body: foo/,
        )
      end

      it "returns an error response" do
        resp = described_class.parse(response)
        expect(resp).to eq('error' => 'foo')
      end

      it "truncates body" do
        response.body *= 1000
        resp = described_class.parse(response)
        expect(resp).to eq('error' => "#{'foo' * 33}fo...")
      end
    end

    context "when response body can't be parsed as JSON" do
      let(:response) { OpenStruct.new(code: 201, body: 'foo') }

      before do
        allow(Airbrake::Loggable.instance).to receive(:error)
      end

      it "logs response body" do
        described_class.parse(response)
        expect(Airbrake::Loggable.instance).to have_received(:error).with(
          /Airbrake: error while parsing body \(.*unexpected token.*\)\. Body: foo/,
        )
      end

      it "returns an error message" do
        expect(described_class.parse(response)['error']).to match(
          /\A#<JSON::ParserError.+>/,
        )
      end
    end
  end
end
