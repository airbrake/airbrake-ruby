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

      it "doesn't set the default root_directory" do
        expect(config.root_directory).to be_nil
      end

      it "doesn't set the default environment" do
        expect(config.environment).to be_nil
      end

      it "doesn't set default notify_environments" do
        expect(config.ignore_environments).to be_empty
      end
    end
  end
end
