RSpec.describe Airbrake do
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
        begin
          described_class.configure(&b)
        rescue Airbrake::Error
          nil
        end
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

    context "when a notifier was configured" do
      before do
        expect(described_class).to receive(:configured?).and_return(true)
      end

      it "closes previously configured notice notifier" do
        expect(described_class).to receive(:close)
        described_class.configure {}
      end
    end

    context "when a notifier wasn't configured" do
      before do
        expect(described_class).to receive(:configured?).and_return(false)
      end

      it "doesn't close previously configured notice notifier" do
        expect(described_class).not_to receive(:close)
        described_class.configure {}
      end
    end

    context "when called multiple times" do
      it "doesn't overwrite performance notifier" do
        described_class.configure {}
        performance_notifier = described_class.performance_notifier

        described_class.configure {}
        expect(described_class.performance_notifier).to eql(performance_notifier)
      end

      it "doesn't overwrite notice notifier" do
        described_class.configure {}
        notice_notifier = described_class.notice_notifier

        described_class.configure {}
        expect(described_class.notice_notifier).to eql(notice_notifier)
      end

      it "doesn't overwrite deploy notifier" do
        described_class.configure {}
        deploy_notifier = described_class.deploy_notifier

        described_class.configure {}
        expect(described_class.deploy_notifier).to eql(deploy_notifier)
      end
    end

    context "when blacklist_keys gets configured" do
      before { allow(Airbrake.notice_notifier).to receive(:add_filter) }

      it "adds blacklist filter" do
        expect(Airbrake.notice_notifier).to receive(:add_filter)
          .with(an_instance_of(Airbrake::Filters::KeysBlacklist))
        described_class.configure { |c| c.blacklist_keys = %w[password] }
      end

      it "initializes blacklist with specified parameters" do
        expect(Airbrake::Filters::KeysBlacklist).to receive(:new).with(%w[password])
        described_class.configure { |c| c.blacklist_keys = %w[password] }
      end
    end

    context "when whitelist_keys gets configured" do
      before { allow(Airbrake.notice_notifier).to receive(:add_filter) }

      it "adds whitelist filter" do
        expect(Airbrake.notice_notifier).to receive(:add_filter)
          .with(an_instance_of(Airbrake::Filters::KeysWhitelist))
        described_class.configure { |c| c.whitelist_keys = %w[banana] }
      end

      it "initializes whitelist with specified parameters" do
        expect(Airbrake::Filters::KeysWhitelist).to receive(:new).with(%w[banana])
        described_class.configure { |c| c.whitelist_keys = %w[banana] }
      end
    end

    context "when root_directory gets configured" do
      before { allow(Airbrake.notice_notifier).to receive(:add_filter) }

      it "adds root directory filter" do
        expect(Airbrake.notice_notifier).to receive(:add_filter)
          .with(an_instance_of(Airbrake::Filters::RootDirectoryFilter))
        described_class.configure { |c| c.root_directory = '/my/path' }
      end

      it "initializes root directory filter with specified path" do
        expect(Airbrake::Filters::RootDirectoryFilter)
          .to receive(:new).with('/my/path')
        described_class.configure { |c| c.root_directory = '/my/path' }
      end

      it "adds git revision filter" do
        expect(Airbrake.notice_notifier).to receive(:add_filter)
          .with(an_instance_of(Airbrake::Filters::GitRevisionFilter))
        described_class.configure { |c| c.root_directory = '/my/path' }
      end

      it "initializes git revision filter with correct root directory" do
        expect(Airbrake::Filters::GitRevisionFilter)
          .to receive(:new).with('/my/path')
        described_class.configure { |c| c.root_directory = '/my/path' }
      end

      it "adds git repository filter" do
        expect(Airbrake.notice_notifier).to receive(:add_filter)
          .with(an_instance_of(Airbrake::Filters::GitRepositoryFilter))
        described_class.configure { |c| c.root_directory = '/my/path' }
      end

      it "initializes git repository filter with correct root directory" do
        expect(Airbrake::Filters::GitRepositoryFilter)
          .to receive(:new).with('/my/path')
        described_class.configure { |c| c.root_directory = '/my/path' }
      end

      it "adds git last checkout filter" do
        expect(Airbrake.notice_notifier).to receive(:add_filter)
          .with(an_instance_of(Airbrake::Filters::GitLastCheckoutFilter))
        described_class.configure { |c| c.root_directory = '/my/path' }
      end

      it "initializes git last checkout filter with correct root directory" do
        expect(Airbrake::Filters::GitLastCheckoutFilter)
          .to receive(:new).with('/my/path')
        described_class.configure { |c| c.root_directory = '/my/path' }
      end
    end
  end

  describe "#reset" do
    context "when Airbrake was previously configured" do
      before do
        expect(described_class).to receive(:configured?).and_return(true)
      end

      it "closes notice notifier" do
        expect(described_class).to receive(:close)
        subject.reset
      end
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
end
