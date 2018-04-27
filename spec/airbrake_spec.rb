require 'spec_helper'

RSpec.describe Airbrake do
  describe ".[]" do
    it "returns a NilNotifier" do
      expect(described_class[:test]).to be_an(Airbrake::NilNotifier)
    end
  end

  let(:default_notifier) do
    described_class.instance_variable_get(:@notifiers)[:default]
  end

  describe ".configure" do
    let(:config_params) { { project_id: 1, project_key: 'abc' } }

    after { described_class.instance_variable_get(:@notifiers).clear }

    it "yields the config" do
      expect do |b|
        begin
          described_class.configure(&b)
        rescue Airbrake::Error
          nil
        end
      end.to yield_with_args(Airbrake::Config)
    end

    context "when invoked with a notifier name" do
      it "sets notifier name to the provided name" do
        described_class.configure(:test) { |c| c.merge(config_params) }
        expect(described_class[:test]).to be_an(Airbrake::Notifier)
      end
    end

    context "when invoked without a notifier name" do
      it "defaults to the :default notifier name" do
        described_class.configure { |c| c.merge(config_params) }
        expect(described_class[:default]).to be_an(Airbrake::Notifier)
      end
    end

    context "when invoked twice with the same notifier name" do
      it "raises Airbrake::Error" do
        described_class.configure { |c| c.merge(config_params) }
        expect do
          described_class.configure { |c| c.merge(config_params) }
        end.to raise_error(
          Airbrake::Error, "the 'default' notifier was already configured"
        )
      end
    end
  end

  describe ".configured?" do
    it "forwards 'configured?' to the notifier" do
      expect(default_notifier).to receive(:configured?)
      described_class.configured?
    end
  end

  describe ".notify" do
    it "forwards 'notify' to the notifier" do
      block = proc {}
      expect(default_notifier).to receive(:notify).with('ex', foo: 'bar', &block)
      described_class.notify('ex', foo: 'bar', &block)
    end
  end

  describe ".notify_sync" do
    it "forwards 'notify_sync' to the notifier" do
      block = proc {}
      expect(default_notifier).to receive(:notify).with('ex', foo: 'bar', &block)
      described_class.notify('ex', foo: 'bar', &block)
    end
  end

  describe ".add_filter" do
    it "forwards 'add_filter' to the notifier" do
      block = proc {}
      expect(default_notifier).to receive(:add_filter).with(nil, &block)
      described_class.add_filter(&block)
    end
  end

  describe ".build_notice" do
    it "forwards 'build_notice' to the notifier" do
      expect(default_notifier).to receive(:build_notice).with('ex', foo: 'bar')
      described_class.build_notice('ex', foo: 'bar')
    end
  end

  describe ".close" do
    it "forwards 'close' to the notifier" do
      expect(default_notifier).to receive(:close)
      described_class.close
    end
  end

  describe ".create_deploy" do
    it "forwards 'create_deploy' to the notifier" do
      expect(default_notifier).to receive(:create_deploy).with(foo: 'bar')
      described_class.create_deploy(foo: 'bar')
    end
  end

  describe ".merge_context" do
    it "forwards 'merge_context' to the notifier" do
      expect(default_notifier).to receive(:merge_context).with(foo: 'bar')
      described_class.merge_context(foo: 'bar')
    end
  end
end
