require 'spec_helper'

RSpec.describe Airbrake::Notifier do
  let(:project_id) { 105138 }
  let(:project_key) { 'fd04e13d806a90f96614ad8e529b2822' }
  let(:localhost) { 'http://localhost:8080' }

  let(:endpoint) do
    "https://airbrake.io/api/v3/projects/#{project_id}/notices?key=#{project_key}"
  end

  let(:airbrake_params) do
    { project_id: project_id,
      project_key: project_key,
      logger: Logger.new(StringIO.new) }
  end

  let(:ex) { AirbrakeTestError.new }

  before do
    stub_request(:post, endpoint).to_return(status: 201, body: '{}')
    @airbrake = described_class.new(airbrake_params)
  end

  describe "options" do
    describe ":host" do
      context "when custom" do
        shared_examples 'endpoint' do |host, endpoint, title|
          example(title) do
            stub_request(:post, endpoint).to_return(status: 201, body: '{}')
            @airbrake = described_class.new(airbrake_params.merge(host: host))
            @airbrake.notify_sync(ex)

            expect(a_request(:post, endpoint)).to have_been_made.once
          end
        end

        path = '/api/v3/projects/105138/notices?key=fd04e13d806a90f96614ad8e529b2822'

        context "given a full host" do
          include_examples('endpoint', localhost = 'http://localhost:8080',
                           URI.join(localhost, path),
                           "sends notices to the specified host's endpoint")
        end

        context "given a full host" do
          include_examples('endpoint', localhost = 'http://localhost',
                           URI.join(localhost, path),
                           "assumes port 80 by default")
        end

        context "given a host without scheme" do
          include_examples 'endpoint', localhost = 'localhost:8080',
                           URI.join("https://#{localhost}", path),
                           "assumes https by default"
        end

        context "given only hostname" do
          include_examples 'endpoint', localhost = 'localhost',
                           URI.join("https://#{localhost}", path),
                           "assumes https and port 80 by default"
        end
      end
    end

    describe ":root_directory" do
      it "filters out frames" do
        params = airbrake_params.merge(root_directory: '/home/kyrylo/code')
        airbrake = described_class.new(params)
        airbrake.notify_sync(ex)

        expect(
          a_request(:post, endpoint).
          with(body: %r|{"file":"\[PROJECT_ROOT\]/airbrake/ruby/spec/airbrake_spec.+|)
        ).to have_been_made.once
      end

      context "when present and is a" do
        shared_examples 'root directory' do |dir|
          it "being included into the notice's payload" do
            params = airbrake_params.merge(root_directory: dir)
            airbrake = described_class.new(params)
            airbrake.notify_sync(ex)

            expect(
              a_request(:post, endpoint).
              with(body: %r{"rootDirectory":"/bingo/bango"})
            ).to have_been_made.once
          end
        end

        context "String" do
          include_examples 'root directory', '/bingo/bango'
        end

        context "Pathname" do
          include_examples 'root directory', Pathname.new('/bingo/bango')
        end
      end
    end

    describe ":proxy" do
      let(:proxy) do
        WEBrick::HTTPServer.new(
          Port: 0,
          Logger: WEBrick::Log.new('/dev/null'),
          AccessLog: []
        )
      end

      let(:requests) { Queue.new }

      let(:proxy_params) do
        { host: 'localhost',
          port: proxy.config[:Port],
          user: 'user',
          password: 'password' }
      end

      before do
        proxy.mount_proc '/' do |req, res|
          requests << req
          res.status = 201
          res.body = "OK\n"
        end

        Thread.new { proxy.start }

        params = airbrake_params.merge(
          proxy: proxy_params,
          host: "http://localhost:#{proxy.config[:Port]}"
        )

        @airbrake = described_class.new(params)
      end

      after { proxy.stop }

      it "is being used if configured" do
        @airbrake.notify_sync(ex)

        proxied_request = requests.pop

        expect(proxied_request.header['proxy-authorization'].first).
          to eq('Basic dXNlcjpwYXNzd29yZA==')

        # rubocop:disable Metrics/LineLength
        expect(proxied_request.request_line).
          to eq("POST http://localhost:#{proxy.config[:Port]}/api/v3/projects/105138/notices?key=fd04e13d806a90f96614ad8e529b2822 HTTP/1.1\r\n")
        # rubocop:enable Metrics/LineLength
      end
    end

    describe ":environment" do
      context "when present" do
        it "being included into the notice's payload" do
          params = airbrake_params.merge(environment: :production)
          airbrake = described_class.new(params)
          airbrake.notify_sync(ex)

          expect(
            a_request(:post, endpoint).
            with(body: /"context":{.*"environment":"production".*}/)
          ).to have_been_made.once
        end
      end
    end

    describe ":ignore_environments" do
      shared_examples 'sent notice' do |params|
        it "sends a notice" do
          airbrake = described_class.new(airbrake_params.merge(params))
          airbrake.notify_sync(ex)

          expect(a_request(:post, endpoint)).to have_been_made
        end
      end

      shared_examples 'ignored notice' do |params|
        it "ignores exceptions occurring in envs that were not configured" do
          airbrake = described_class.new(airbrake_params.merge(params))
          airbrake.notify_sync(ex)

          expect(a_request(:post, endpoint)).not_to have_been_made
        end
      end

      context "when env is set and ignore_environments doesn't mention it" do
        params = {
          environment: :development,
          ignore_environments: [:production]
        }

        include_examples 'sent notice', params
      end

      context "when the current env and notify envs are the same" do
        params = {
          environment: :development,
          ignore_environments: [:production, :development]
        }

        include_examples 'ignored notice', params
      end

      context "when the current env is not set and notify envs are present" do
        params = { ignore_environments: [:production, :development] }

        include_examples 'sent notice', params
      end

      context "when the current env is set and notify envs aren't" do
        include_examples 'sent notice', environment: :development
      end
    end

    describe ":always_async" do
      it "doesn't fall back to synchronous delivery when the async sender is dead" do
        out = StringIO.new
        notifier = described_class.new(
          airbrake_params.merge(logger: Logger.new(out), always_async: true))
        async_sender = notifier.instance_variable_get(:@async_sender)

        expect(async_sender).to have_workers
        async_sender.instance_variable_get(:@workers).list.each(&:kill)
        sleep 1
        expect(async_sender).not_to have_workers

        expect(async_sender).to receive(:send)
        expect(out.string).to_not match(/falling back to sync delivery/)
        notifier.notify('bango')

        notifier.close
      end
    end
  end
end
