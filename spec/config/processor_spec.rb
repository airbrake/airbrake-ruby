RSpec.describe Airbrake::Config::Processor do
  let(:notifier) { Airbrake::NoticeNotifier.new }

  describe "#process_blocklist" do
    let(:config) { Airbrake::Config.new(blocklist_keys: %w[a b c]) }

    context "when there ARE blocklist keys" do
      it "adds the blocklist filter" do
        described_class.new(config).process_blocklist(notifier)
        expect(notifier.has_filter?(Airbrake::Filters::KeysBlocklist)).to eq(true)
      end
    end

    context "when there are NO blocklist keys" do
      let(:config) { Airbrake::Config.new(blocklist_keys: %w[]) }

      it "doesn't add the blocklist filter" do
        described_class.new(config).process_blocklist(notifier)
        expect(notifier.has_filter?(Airbrake::Filters::KeysBlocklist))
          .to eq(false)
      end
    end
  end

  describe "#process_allowlist" do
    let(:config) { Airbrake::Config.new(allowlist_keys: %w[a b c]) }

    context "when there ARE allowlist keys" do
      it "adds the allowlist filter" do
        described_class.new(config).process_allowlist(notifier)
        expect(notifier.has_filter?(Airbrake::Filters::KeysAllowlist)).to eq(true)
      end
    end

    context "when there are NO allowlist keys" do
      let(:config) { Airbrake::Config.new(allowlist_keys: %w[]) }

      it "doesn't add the allowlist filter" do
        described_class.new(config).process_allowlist(notifier)
        expect(notifier.has_filter?(Airbrake::Filters::KeysAllowlist))
          .to eq(false)
      end
    end
  end

  describe "#process_remote_configuration" do
    context "when the config doesn't define a project_id" do
      let(:config) { Airbrake::Config.new(project_id: nil) }

      it "doesn't set remote settings" do
        expect(Airbrake::RemoteSettings).not_to receive(:poll)
        described_class.new(config).process_remote_configuration
      end
    end

    context "when the config defines a project_id" do
      let(:config) do
        Airbrake::Config.new(project_id: 123)
      end

      it "sets remote settings" do
        expect(Airbrake::RemoteSettings).to receive(:poll)
        described_class.new(config).process_remote_configuration
      end
    end
  end

  describe "#add_filters" do
    context "when there's a root directory" do
      let(:config) { Airbrake::Config.new(root_directory: '/abc') }

      it "adds RootDirectoryFilter" do
        described_class.new(config).add_filters(notifier)
        expect(notifier.has_filter?(Airbrake::Filters::RootDirectoryFilter))
          .to eq(true)
      end

      it "adds GitRevisionFilter" do
        described_class.new(config).add_filters(notifier)
        expect(notifier.has_filter?(Airbrake::Filters::GitRevisionFilter))
          .to eq(true)
      end

      it "adds GitRepositoryFilter" do
        described_class.new(config).add_filters(notifier)
        expect(notifier.has_filter?(Airbrake::Filters::GitRepositoryFilter))
          .to eq(true)
      end

      it "adds GitLastCheckoutFilter" do
        described_class.new(config).add_filters(notifier)
        expect(notifier.has_filter?(Airbrake::Filters::GitLastCheckoutFilter))
          .to eq(true)
      end
    end

    context "when there's NO root directory" do
      let(:config) { Airbrake::Config.new(root_directory: nil) }

      it "doesn't add RootDirectoryFilter" do
        described_class.new(config).add_filters(notifier)
        expect(notifier.has_filter?(Airbrake::Filters::RootDirectoryFilter))
          .to eq(false)
      end

      it "doesn't add GitRevisionFilter" do
        described_class.new(config).add_filters(notifier)
        expect(notifier.has_filter?(Airbrake::Filters::GitRevisionFilter))
          .to eq(false)
      end

      it "doesn't add GitRepositoryFilter" do
        described_class.new(config).add_filters(notifier)
        expect(notifier.has_filter?(Airbrake::Filters::GitRepositoryFilter))
          .to eq(false)
      end

      it "doesn't add GitLastCheckoutFilter" do
        described_class.new(config).add_filters(notifier)
        expect(notifier.has_filter?(Airbrake::Filters::GitLastCheckoutFilter))
          .to eq(false)
      end
    end
  end

  describe "#poll_callback" do
    let(:logger) { Logger.new(File::NULL) }

    let(:config) do
      Airbrake::Config.new(
        project_id: 123,
        logger: logger,
      )
    end

    let(:data) do
      instance_double(Airbrake::RemoteSettings::SettingsData)
    end

    before do
      allow(data).to receive(:to_h)
      allow(data).to receive(:error_host)
      allow(data).to receive(:apm_host)
      allow(data).to receive(:error_notifications?)
      allow(data).to receive(:performance_stats?)
    end

    it "logs given data" do
      expect(logger).to receive(:debug).with(/applying remote settings/)
      described_class.new(config).poll_callback(data)
    end

    it "sets the error_notifications option" do
      config.error_notifications = false
      expect(data).to receive(:error_notifications?).and_return(true)

      described_class.new(config).poll_callback(data)
      expect(config.error_notifications).to eq(true)
    end

    it "sets the performance_stats option" do
      config.performance_stats = false
      expect(data).to receive(:performance_stats?).and_return(true)

      described_class.new(config).poll_callback(data)
      expect(config.performance_stats).to eq(true)
    end

    context "when error_host returns a value" do
      it "sets the error_host option" do
        config.error_host = 'http://api.airbrake.io'
        allow(data).to receive(:error_host).and_return('https://api.example.com')

        described_class.new(config).poll_callback(data)
        expect(config.error_host).to eq('https://api.example.com')
      end
    end

    context "when error_host returns nil" do
      it "doesn't modify the error_host option" do
        config.error_host = 'http://api.airbrake.io'
        allow(data).to receive(:error_host).and_return(nil)

        described_class.new(config).poll_callback(data)
        expect(config.error_host).to eq('http://api.airbrake.io')
      end
    end

    context "when apm_host returns a value" do
      it "sets the apm_host option" do
        config.apm_host = 'http://api.airbrake.io'
        allow(data).to receive(:apm_host).and_return('https://api.example.com')

        described_class.new(config).poll_callback(data)
        expect(config.apm_host).to eq('https://api.example.com')
      end
    end

    context "when apm_host returns nil" do
      it "doesn't modify the apm_host option" do
        config.apm_host = 'http://api.airbrake.io'
        allow(data).to receive(:apm_host).and_return(nil)

        described_class.new(config).poll_callback(data)
        expect(config.apm_host).to eq('http://api.airbrake.io')
      end
    end
  end
end
