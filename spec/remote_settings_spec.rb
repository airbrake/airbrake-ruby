RSpec.describe Airbrake::RemoteSettings do
  let(:project_id) { 123 }

  let(:endpoint) do
    "https://staging-notifier-configs.s3.amazonaws.com/2020-06-18/config/" \
    "#{project_id}/config.json"
  end

  let(:body) do
    {
      'poll_sec' => 1,
      'settings' => [
        {
          'title' => 'apm',
          'enabled' => false,
        },
        {
          'title' => 'errors',
          'enabled' => true,
        },
      ],
    }
  end

  before do
    stub_request(:get, endpoint).to_return(status: 200, body: body.to_json)
  end

  describe ".poll" do
    context "when no errors are raised" do
      it "makes a request to AWS S3" do
        remote_settings = described_class.poll(project_id) {}
        sleep(0.1)
        remote_settings.stop_polling

        expect(a_request(:get, endpoint)).to have_been_made.at_least_once
      end

      it "fetches remote settings" do
        settings = nil
        remote_settings = described_class.poll(project_id) do |data|
          settings = data
        end
        sleep(0.1)
        remote_settings.stop_polling

        expect(settings.error_notifications?).to eq(true)
        expect(settings.performance_stats?).to eq(false)
        expect(settings.interval).to eq(1)
      end
    end

    context "when an error is raised while making a HTTP request" do
      before do
        allow(Net::HTTP).to receive(:get).and_raise(StandardError)
      end

      it "doesn't fetch remote settings" do
        settings = nil
        remote_settings = described_class.poll(project_id) do |data|
          settings = data
        end
        sleep(0.1)
        remote_settings.stop_polling

        expect(a_request(:get, endpoint)).not_to have_been_made
        expect(settings.interval).to eq(600)
      end
    end

    context "when an error is raised while parsing returned JSON" do
      before do
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
      end

      it "doesn't update settings data" do
        settings = nil
        remote_settings = described_class.poll(project_id) do |data|
          settings = data
        end
        sleep(0.1)
        remote_settings.stop_polling

        expect(a_request(:get, endpoint)).to have_been_made.once
        expect(settings.interval).to eq(600)
      end
    end

    context "when API returns an XML response" do
      before do
        stub_request(:get, endpoint).to_return(status: 200, body: '<?xml ...')
      end

      it "doesn't update settings data" do
        settings = nil
        remote_settings = described_class.poll(project_id) do |data|
          settings = data
        end
        sleep(0.1)
        remote_settings.stop_polling

        expect(a_request(:get, endpoint)).to have_been_made.once
        expect(settings.interval).to eq(600)
      end
    end

    context "when a config route is specified in the returned data" do
      let(:new_endpoint) { 'http://example.com' }

      let(:body) do
        { 'config_route' => new_endpoint, 'poll_sec' => 0.1 }
      end

      before do
        stub_request(:get, new_endpoint).to_return(status: 200, body: body.to_json)
      end

      it "makes the next request to the specified config route" do
        settings = nil
        remote_settings = described_class.poll(project_id) do |data|
          settings = data
        end
        sleep(0.2)

        remote_settings.stop_polling

        expect(a_request(:get, endpoint)).to have_been_made.once
        expect(a_request(:get, new_endpoint)).to have_been_made.once
      end
    end
  end
end
