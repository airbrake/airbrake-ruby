require 'spec_helper'

RSpec.describe Airbrake::Response do
  describe ".parse" do
    let(:out) { StringIO.new }
    let(:logger) { Logger.new(out) }

    context "when response code is 201" do
      it "logs response body" do
        described_class.parse(OpenStruct.new(code: 201, body: '{}'), logger)
        expect(out.string).to match(/Airbrake: {}/)
      end
    end

    [400, 401, 403, 420].each do |code|
      context "when response code is #{code}" do
        it "logs response message" do
          described_class.parse(
            OpenStruct.new(code: code, body: '{"message":"foo"}'), logger
          )
          expect(out.string).to match(/Airbrake: foo/)
        end
      end
    end

    context "when response code is 429" do
      let(:response) { OpenStruct.new(code: 429, body: '{"message":"rate limited"}') }
      it "logs response message" do
        described_class.parse(response, logger)
        expect(out.string).to match(/Airbrake: rate limited/)
      end

      it "returns an error response" do
        time = Time.now
        allow(Time).to receive(:now).and_return(time)

        resp = described_class.parse(response, logger)
        expect(resp).to include(
          'error' => '**Airbrake: rate limited',
          'rate_limit_reset' => time
        )
      end
    end

    context "when response code is unhandled" do
      let(:response) { OpenStruct.new(code: 500, body: 'foo') }

      it "logs response body" do
        described_class.parse(response, logger)
        expect(out.string).to match(/Airbrake: unexpected code \(500\)\. Body: foo/)
      end

      it "returns an error response" do
        resp = described_class.parse(response, logger)
        expect(resp).to eq('error' => 'foo')
      end

      it "truncates body" do
        response.body *= 1000
        resp = described_class.parse(response, logger)
        expect(resp).to eq('error' => ('foo' * 33) + 'fo...')
      end
    end

    context "when response body can't be parsed as JSON" do
      let(:response) { OpenStruct.new(code: 201, body: 'foo') }

      it "logs response body" do
        described_class.parse(response, logger)
        expect(out.string).to match(
          /Airbrake: error while parsing body \(.*unexpected token.*\)\. Body: foo/
        )
      end

      it "returns an error message" do
        expect(described_class.parse(response, logger)['error']).to match(
          /\A#<JSON::ParserError.+>/
        )
      end
    end
  end
end
