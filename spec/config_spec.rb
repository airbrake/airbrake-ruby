require 'spec_helper'

RSpec.describe Airbrake::Config do
  let(:config) { described_class.new }

  describe "#new" do
    describe "options" do
      it "doesn't set the default project_id" do
        expect(config.project_id).to be_nil
      end

      it "doesn't set the default project_key" do
        expect(config.project_key).to be_nil
      end

      it "doesn't set the default proxy" do
        expect(config.proxy).to be_empty
      end

      it "sets the default logger" do
        expect(config.logger).to be_a Logger
      end

      it "doesn't set the default app_version" do
        expect(config.app_version).to be_nil
      end

      it "sets the default versions" do
        expect(config.versions).to be_empty
      end

      it "sets the default host" do
        expect(config.host).to eq('https://airbrake.io')
      end

      it "sets the default endpoint" do
        expect(config.endpoint).not_to be_nil
      end

      it "creates a new Config and merges it with the user config" do
        cfg = described_class.new(logger: StringIO.new)
        expect(cfg.logger).to be_a StringIO
      end

      it "raises error on unknown config options" do
        expect { described_class.new(unknown_option: true) }.
          to raise_error(Airbrake::Error, /unknown option/)
      end

      it "sets the default number of workers" do
        expect(config.workers).to eq(1)
      end

      it "sets the default number of queue size" do
        expect(config.queue_size).to eq(100)
      end

      it "sets the default root_directory" do
        expect(config.root_directory).to eq Bundler.root.realpath.to_s
      end

      it "doesn't set the default environment" do
        expect(config.environment).to be_nil
      end

      it "doesn't set default notify_environments" do
        expect(config.ignore_environments).to be_empty
      end

      it "doesn't set default timeout" do
        expect(config.timeout).to be_nil
      end

      it "doesn't set default blacklist" do
        expect(config.blacklist_keys).to be_empty
      end

      it "doesn't set default whitelist" do
        expect(config.whitelist_keys).to be_empty
      end
    end
  end

  describe "#valid?" do
    context "when project_id is nil" do
      it "returns false" do
        config.project_id = nil
        config.project_key = '123'

        expect(config).not_to be_valid
      end
    end

    context "when project_key is nil" do
      it "returns false" do
        config.project_id = 123
        config.project_key = nil

        expect(config).not_to be_valid
      end
    end

    context "when the current environment is ignored" do
      context "and when the notifier misconfigures configure project_key & project_id" do
        it "returns true" do
          config.project_id = Object.new
          config.project_key = Object.new
          config.environment = :bingo
          config.ignore_environments = [:bingo]

          expect(config).to be_valid
        end
      end

      context "and when the notifier configures project_key & project_id" do
        it "returns true" do
          config.project_id = 123
          config.project_key = '321'
          config.environment = :bingo
          config.ignore_environments = [:bingo]

          expect(config).to be_valid
        end
      end
    end

    context "when the project_id value is not a number" do
      it "returns false" do
        config.project_id = 'bingo'
        config.project_key = '321'

        expect(config).not_to be_valid
      end
    end

    context "when the project_id value is a String number" do
      it "returns true" do
        config.project_id = '123'
        config.project_key = '321'

        expect(config).to be_valid
      end
    end

    context "when the project_key value is not a String" do
      it "returns false" do
        config.project_id = 123
        config.project_key = 321

        expect(config).not_to be_valid
      end
    end

    context "when the project_key value is an empty String" do
      it "returns false" do
        config.project_id = 123
        config.project_key = ''

        expect(config).not_to be_valid
      end
    end

    context "when the environment value is not a String" do
      let(:out) { StringIO.new }
      let(:config) { described_class.new(logger: Logger.new(out)) }

      before do
        config.project_id = 123
        config.project_key = '321'

        config.environment = ['bingo']
      end

      it "returns false" do
        expect(config).not_to be_valid
      end
    end
  end

  describe "#ignored_environment?" do
    describe "warnings" do
      let(:out) { StringIO.new }
      let(:config) { described_class.new(logger: Logger.new(out)) }

      context "when 'ignore_environments' is set and 'environment' isn't" do
        it "prints a warning" do
          config.ignore_environments = [:bingo]

          expect(config.ignored_environment?).to be_falsey
          expect(out.string).to match(/ignore_environments' has no effect/)
        end
      end

      context "when 'ignore_environments' is set along with 'environment'" do
        it "doesn't print a warning" do
          config.environment = :bango
          config.ignore_environments = [:bingo]

          expect(config.ignored_environment?).to be_falsey
          expect(out.string).to be_empty
        end
      end

      context "when 'ignore_environments' isn't set and 'environment' isn't set too" do
        it "doesn't print a warning" do
          expect(config.ignored_environment?).to be_falsey
          expect(out.string).to be_empty
        end
      end
    end

    describe "environment value types" do
      context "when 'environment' is a String" do
        context "and when 'ignore_environments' contains Symbols" do
          it "returns true" do
            config.environment = 'bango'
            config.ignore_environments = [:bango]

            expect(config.ignored_environment?).to be_truthy
          end
        end
      end

      context "when 'environment' is a Symbol" do
        context "and when 'ignore_environments' contains Strings" do
          it "returns true" do
            config.environment = :bango
            config.ignore_environments = %w[bango]

            expect(config.ignored_environment?).to be_truthy
          end
        end
      end
    end
  end

  describe "#endpoint" do
    context "when host is configured with a URL with a slug" do
      before do
        config.project_id = 1
        config.project_key = '2'
      end

      context "and with a trailing slash" do
        it "sets the endpoint with the slug" do
          config.host = 'https://localhost/bingo/'
          expect(config.endpoint.to_s).
            to eq('https://localhost/bingo/api/v3/projects/1/notices')
        end
      end

      context "and without a trailing slash" do
        it "sets the endpoint without the slug" do
          config.host = 'https://localhost/bingo'
          expect(config.endpoint.to_s).
            to eq('https://localhost/api/v3/projects/1/notices')
        end
      end
    end
  end
end
