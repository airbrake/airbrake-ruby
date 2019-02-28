RSpec.describe Airbrake::Config do
  describe "#new" do
    describe "options" do
      it "doesn't set the default project_id" do
        expect(subject.project_id).to be_nil
      end

      it "doesn't set the default project_key" do
        expect(subject.project_key).to be_nil
      end

      it "doesn't set the default proxy" do
        expect(subject.proxy).to be_empty
      end

      it "sets the default logger" do
        expect(subject.logger).to be_a Logger
      end

      it "doesn't set the default app_version" do
        expect(subject.app_version).to be_nil
      end

      it "sets the default versions" do
        expect(subject.versions).to be_empty
      end

      it "sets the default host" do
        expect(subject.host).to eq('https://api.airbrake.io')
      end

      it "sets the default endpoint" do
        expect(subject.endpoint).not_to be_nil
      end

      it "creates a new Config and merges it with the user config" do
        config = described_class.new(logger: StringIO.new)
        expect(config.logger).to be_a(StringIO)
      end

      it "raises error on unknown config options" do
        expect { described_class.new(unknown_option: true) }
          .to raise_error(Airbrake::Error, /unknown option/)
      end

      it "sets the default number of workers" do
        expect(subject.workers).to eq(1)
      end

      it "sets the default number of queue size" do
        expect(subject.queue_size).to eq(100)
      end

      it "sets the default root_directory" do
        expect(subject.root_directory).to eq Bundler.root.realpath.to_s
      end

      it "doesn't set the default environment" do
        expect(subject.environment).to be_nil
      end

      it "doesn't set default notify_environments" do
        expect(subject.ignore_environments).to be_empty
      end

      it "doesn't set default timeout" do
        expect(subject.timeout).to be_nil
      end

      it "doesn't set default blacklist" do
        expect(subject.blacklist_keys).to be_empty
      end

      it "doesn't set default whitelist" do
        expect(subject.whitelist_keys).to be_empty
      end

      it "disables performance stats by default" do
        expect(subject.performance_stats).to be_falsey
      end

      it "sets the default performance_stats_flush_period" do
        expect(subject.performance_stats_flush_period).to eq(15)
      end
    end
  end

  describe "#valid?" do
    it "returns true when #validate returns a resolved promise" do
      expect(subject).to receive(:validate).and_return(OpenStruct.new(value: :ok))
      expect(subject.valid?).to be_truthy
    end

    it "it returns false when #validate returns a rejected promise" do
      expect(subject).to receive(:validate)
        .and_return(OpenStruct.new(value: { 'error' => '' }))
      expect(subject.valid?).to be_falsey
    end
  end

  describe "#ignored_environment?" do
    it "returns false when Validator returns a resolved promise" do
      expect(Airbrake::Config::Validator).to receive(:check_notify_ability)
        .and_return(OpenStruct.new(value: :ok))
      expect(subject.ignored_environment?).to be_falsey
    end

    it "returns true when Validator returns a rejected promise" do
      expect(Airbrake::Config::Validator).to receive(:check_notify_ability)
        .and_return(OpenStruct.new(value: { 'error' => '' }))
      expect(subject.ignored_environment?).to be_truthy
    end
  end

  describe "#endpoint" do
    context "when host is configured with a URL with a slug" do
      let(:config) { described_class.new(project_id: 1, project_key: '2') }

      context "and with a trailing slash" do
        it "sets the endpoint with the slug" do
          config.host = 'https://localhost/bingo/'
          expect(config.endpoint.to_s)
            .to eq('https://localhost/bingo/api/v3/projects/1/notices')
        end
      end

      context "and without a trailing slash" do
        it "sets the endpoint without the slug" do
          config.host = 'https://localhost/bingo'
          expect(config.endpoint.to_s)
            .to eq('https://localhost/api/v3/projects/1/notices')
        end
      end
    end
  end

  describe "#validate" do
    it "returns a promise" do
      expect(subject.validate).to be_an(Airbrake::Promise)
    end
  end
end
