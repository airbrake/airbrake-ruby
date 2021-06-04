RSpec.describe Airbrake do
  let(:remote_settings) { instance_double(Airbrake::RemoteSettings) }

  before do
    allow(Airbrake::RemoteSettings).to receive(:poll).and_return(remote_settings)
    allow(remote_settings).to receive(:stop_polling)
  end

  after { described_class.instance_variable_set(:@remote_settings, nil) }

  it "gets initialized with a performance notifier" do
    expect(described_class.performance_notifier).not_to be_nil
  end

  it "gets initialized with a notice notifier" do
    expect(described_class.notice_notifier).not_to be_nil
  end

  it "gets initialized with a deploy notifier" do
    expect(described_class.deploy_notifier).not_to be_nil
  end

  describe ".configure" do
    before do
      Airbrake::Config.instance = Airbrake::Config.new
      described_class.reset
    end

    after { described_class.reset }

    it "yields the config" do
      expect do |b|
        described_class.configure(&b)
      rescue Airbrake::Error
        nil
      end.to yield_with_args(Airbrake::Config)
    end

    it "sets logger to Airbrake::Loggable" do
      logger = Logger.new(File::NULL)
      described_class.configure do |c|
        c.project_id = 1
        c.project_key = '123'
        c.logger = logger
      end

      expect(Airbrake::Loggable.instance).to eql(logger)
    end

    it "makes Airbrake configured" do
      expect(described_class).not_to be_configured

      described_class.configure do |c|
        c.project_id = 1
        c.project_key = '2'
      end

      expect(described_class).to be_configured
    end

    context "when called multiple times" do
      it "doesn't overwrite performance notifier" do
        described_class.configure { anything }
        performance_notifier = described_class.performance_notifier

        described_class.configure { anything }
        expect(described_class.performance_notifier).to eql(performance_notifier)
      end

      it "doesn't overwrite notice notifier" do
        described_class.configure { anything }
        notice_notifier = described_class.notice_notifier

        described_class.configure { anything }
        expect(described_class.notice_notifier).to eql(notice_notifier)
      end

      it "doesn't overwrite deploy notifier" do
        described_class.configure { anything }
        deploy_notifier = described_class.deploy_notifier

        described_class.configure { anything }
        expect(described_class.deploy_notifier).to eql(deploy_notifier)
      end

      it "doesn't append the same notice notifier filters over and over" do
        described_class.configure do |c|
          c.project_id = 1
          c.project_key = '2'
        end

        allow(described_class.notice_notifier).to receive(:add_filter)

        10.times { described_class.configure { anything } }

        expect(described_class.notice_notifier).not_to have_received(:add_filter)
      end

      it "appends some default filters" do
        allow(described_class.notice_notifier).to receive(:add_filter)

        described_class.configure do |c|
          c.project_id = 1
          c.project_key = '2'
        end

        expect(described_class.notice_notifier).to have_received(:add_filter).with(
          an_instance_of(Airbrake::Filters::RootDirectoryFilter),
        )
      end
    end

    context "when blocklist_keys gets configured" do
      before { allow(described_class.notice_notifier).to receive(:add_filter) }

      it "adds blocklist filter" do
        allow(described_class.notice_notifier).to receive(:add_filter)

        described_class.configure { |c| c.blocklist_keys = %w[password] }

        expect(described_class.notice_notifier).to have_received(:add_filter)
          .with(an_instance_of(Airbrake::Filters::KeysBlocklist))
      end

      it "initializes blocklist with specified parameters" do
        allow(Airbrake::Filters::KeysBlocklist).to receive(:new)

        described_class.configure { |c| c.blocklist_keys = %w[password] }

        expect(Airbrake::Filters::KeysBlocklist)
          .to have_received(:new).with(%w[password])
      end
    end

    context "when allowlist_keys gets configured" do
      before { allow(described_class.notice_notifier).to receive(:add_filter) }

      it "adds allowlist filter" do
        described_class.configure { |c| c.allowlist_keys = %w[banana] }
        expect(described_class.notice_notifier).to have_received(:add_filter)
          .with(an_instance_of(Airbrake::Filters::KeysAllowlist))
      end

      it "initializes allowlist with specified parameters" do
        allow(Airbrake::Filters::KeysAllowlist).to receive(:new)

        described_class.configure { |c| c.allowlist_keys = %w[banana] }
        expect(Airbrake::Filters::KeysAllowlist)
          .to have_received(:new).with(%w[banana])
      end
    end

    context "when root_directory gets configured" do
      before { allow(described_class.notice_notifier).to receive(:add_filter) }

      it "adds root directory filter" do
        described_class.configure { |c| c.root_directory = '/my/path' }

        expect(described_class.notice_notifier).to have_received(:add_filter)
          .with(an_instance_of(Airbrake::Filters::RootDirectoryFilter))
      end

      it "initializes root directory filter with specified path" do
        allow(Airbrake::Filters::RootDirectoryFilter).to receive(:new)
        described_class.configure { |c| c.root_directory = '/my/path' }

        expect(Airbrake::Filters::RootDirectoryFilter)
          .to have_received(:new).with('/my/path')
      end

      it "adds git revision filter" do
        described_class.configure { |c| c.root_directory = '/my/path' }
        expect(described_class.notice_notifier).to have_received(:add_filter)
          .with(an_instance_of(Airbrake::Filters::GitRevisionFilter))
      end

      it "initializes git revision filter with correct root directory" do
        allow(Airbrake::Filters::GitRevisionFilter).to receive(:new)
        described_class.configure { |c| c.root_directory = '/my/path' }

        expect(Airbrake::Filters::GitRevisionFilter)
          .to have_received(:new).with('/my/path')
      end

      it "adds git repository filter" do
        described_class.configure { |c| c.root_directory = '/my/path' }

        expect(described_class.notice_notifier).to have_received(:add_filter)
          .with(an_instance_of(Airbrake::Filters::GitRepositoryFilter))
      end

      it "initializes git repository filter with correct root directory" do
        allow(Airbrake::Filters::GitRepositoryFilter).to receive(:new)

        described_class.configure { |c| c.root_directory = '/my/path' }

        expect(Airbrake::Filters::GitRepositoryFilter)
          .to have_received(:new).with('/my/path')
      end

      it "adds git last checkout filter" do
        described_class.configure { |c| c.root_directory = '/my/path' }
        expect(described_class.notice_notifier).to have_received(:add_filter)
          .with(an_instance_of(Airbrake::Filters::GitLastCheckoutFilter))
      end

      it "initializes git last checkout filter with correct root directory" do
        allow(Airbrake::Filters::GitLastCheckoutFilter).to receive(:new)
        described_class.configure { |c| c.root_directory = '/my/path' }

        expect(Airbrake::Filters::GitLastCheckoutFilter)
          .to have_received(:new).with('/my/path')
      end
    end
  end

  describe ".notify_request" do
    before do
      allow(described_class.performance_notifier).to receive(:notify)
    end

    context "when :stash key is not provided" do
      it "doesn't add anything to the stash of the request" do
        described_class.notify_request(
          method: 'GET',
          route: '/',
          status_code: 200,
          timing: 1,
        )

        expect(
          described_class.performance_notifier,
        ).to have_received(:notify) do |request|
          expect(request.stash).to be_empty
        end
      end
    end

    context "when :stash key is provided" do
      it "adds the value as the stash of the request" do
        described_class.notify_request(
          {
            method: 'GET',
            route: '/',
            status_code: 200,
            timing: 1,
          },
          request_id: 1,
        )

        expect(
          described_class.performance_notifier,
        ).to have_received(:notify) do |request|
          expect(request.stash).to eq(request_id: 1)
        end
      end
    end
  end

  describe ".notify_request_sync" do
    it "notifies request synchronously" do
      allow(described_class.performance_notifier).to receive(:notify_sync)

      described_class.notify_request_sync(
        {
          method: 'GET',
          route: '/',
          status_code: 200,
          timing: 1,
        },
        request_id: 1,
      )

      expect(described_class.performance_notifier).to have_received(:notify_sync)
    end
  end

  describe ".notify_query" do
    before do
      allow(described_class.performance_notifier).to receive(:notify)
    end

    context "when :stash key is not provided" do
      it "doesn't add anything to the stash of the query" do
        described_class.notify_query(
          method: 'GET',
          route: '/',
          query: '',
          timing: 1,
        )

        expect(
          described_class.performance_notifier,
        ).to have_received(:notify) do |query|
          expect(query.stash).to be_empty
        end
      end
    end

    context "when :stash key is provided" do
      it "adds the value as the stash of the query" do
        described_class.notify_query(
          {
            method: 'GET',
            route: '/',
            query: '',
            timing: 1,
          },
          request_id: 1,
        )

        expect(
          described_class.performance_notifier,
        ).to have_received(:notify) do |query|
          expect(query.stash).to eq(request_id: 1)
        end
      end
    end
  end

  describe ".notify_query_sync" do
    it "notifies query synchronously" do
      allow(described_class.performance_notifier).to receive(:notify_sync)

      described_class.notify_query_sync(
        {
          method: 'GET',
          route: '/',
          query: '',
          timing: 1,
        },
        request_id: 1,
      )

      expect(described_class.performance_notifier).to have_received(:notify_sync)
    end
  end

  describe ".notify_performance_breakdown" do
    before do
      allow(described_class.performance_notifier).to receive(:notify)
    end

    context "when :stash key is not provided" do
      it "doesn't add anything to the stash of the performance breakdown" do
        described_class.notify_query(
          method: 'GET',
          route: '/',
          query: '',
          timing: 1,
        )

        expect(
          described_class.performance_notifier,
        ).to have_received(:notify) do |query|
          expect(query.stash).to be_empty
        end
      end
    end

    context "when :stash key is provided" do
      it "adds the value as the stash of the performance breakdown" do
        described_class.notify_performance_breakdown(
          {
            method: 'GET',
            route: '/',
            response_type: :html,
            groups: {},
            timing: 1,
          },
          request_id: 1,
        )

        expect(
          described_class.performance_notifier,
        ).to have_received(:notify) do |performance_breakdown|
          expect(performance_breakdown.stash).to eq(request_id: 1)
        end
      end
    end
  end

  describe ".notify_performance_breakdown_sync" do
    it "notifies performance breakdown synchronously" do
      allow(described_class.performance_notifier).to receive(:notify_sync)

      described_class.notify_performance_breakdown_sync(
        {
          method: 'GET',
          route: '/',
          response_type: :html,
          groups: {},
          timing: 1,
        },
        request_id: 1,
      )

      expect(described_class.performance_notifier).to have_received(:notify_sync)
    end
  end

  describe ".notify_queue" do
    before do
      allow(described_class.performance_notifier).to receive(:notify)
    end

    context "when :stash key is not provided" do
      it "doesn't add anything to the stash of the queue" do
        described_class.notify_queue(
          queue: 'bananas',
          error_count: 10,
        )

        expect(
          described_class.performance_notifier,
        ).to have_received(:notify) do |queue|
          expect(queue.stash).to be_empty
        end
      end
    end

    context "when :stash key is provided" do
      it "adds the value as the stash of the queue" do
        described_class.notify_queue(
          {
            queue: 'bananas',
            error_count: 10,
          },
          request_id: 1,
        )

        expect(
          described_class.performance_notifier,
        ).to have_received(:notify) do |queue|
          expect(queue.stash).to eq(request_id: 1)
        end
      end
    end
  end

  describe ".notify_queue_sync" do
    it "notifies queue synchronously" do
      allow(described_class.performance_notifier).to receive(:notify_sync)

      described_class.notify_queue_sync(
        {
          queue: 'bananas',
          error_count: 10,
        },
        request_id: 1,
      )

      expect(described_class.performance_notifier).to have_received(:notify_sync)
    end
  end

  describe ".performance_notifier" do
    it "returns a performance notifier" do
      expect(described_class.performance_notifier)
        .to be_an(Airbrake::PerformanceNotifier)
    end
  end

  describe ".notice_notifier" do
    it "returns a notice notifier" do
      expect(described_class.notice_notifier).to be_an(Airbrake::NoticeNotifier)
    end
  end

  describe ".deploy_notifier" do
    it "returns a deploy notifier" do
      expect(described_class.deploy_notifier).to be_an(Airbrake::DeployNotifier)
    end
  end

  # rubocop:disable RSpec/MessageSpies
  describe ".close" do
    after { described_class.reset }

    context "when notice_notifier is defined" do
      it "gets closed" do
        expect(described_class.notice_notifier).to receive(:close)
      end
    end

    context "when notice_notifier is undefined" do
      it "doesn't get closed (because it wasn't initialized)" do
        described_class.instance_variable_set(:@notice_notifier, nil)
        expect_any_instance_of(Airbrake::NoticeNotifier).not_to receive(:close)
      end
    end

    context "when performance_notifier is defined" do
      it "gets closed" do
        expect(described_class.performance_notifier).to receive(:close)
      end
    end

    context "when perforance_notifier is undefined" do
      it "doesn't get closed (because it wasn't initialized)" do
        described_class.instance_variable_set(:@performance_notifier, nil)
        expect_any_instance_of(Airbrake::PerformanceNotifier)
          .not_to receive(:close)
      end
    end

    context "when remote settings are defined" do
      it "stops polling" do
        described_class.instance_variable_set(:@remote_settings, remote_settings)
        expect(remote_settings).to receive(:stop_polling)
      end
    end

    context "when remote settings are undefined" do
      it "doesn't stop polling (because they weren't initialized)" do
        described_class.instance_variable_set(:@remote_settings, nil)
        expect(remote_settings).not_to receive(:stop_polling)
      end
    end
  end
  # rubocop:enable RSpec/MessageSpies
end
