require 'spec_helper'

RSpec.describe Airbrake::DeployNotifier do
  let(:user_config) { { project_id: 1, project_key: 'banana' } }
  let(:config) { Airbrake::Config.new(user_config) }

  subject { described_class.new(config) }

  describe "#initialize" do
    it "raises error if config is invalid" do
      expect { described_class.new(Airbrake::Config.new(project_id: 1)) }.
        to raise_error(Airbrake::Error)
    end
  end

  describe "#notify" do
    it "returns a promise" do
      stub_request(:post, 'https://api.airbrake.io/api/v4/projects/1/deploys').
        to_return(status: 201, body: '{}')
      expect(subject.notify({})).to be_an(Airbrake::Promise)
    end

    context "when environment is configured" do
      it "prefers the passed environment to the config env" do
        expect_any_instance_of(Airbrake::SyncSender).to receive(:send).with(
          { environment: 'barenv' },
          instance_of(Airbrake::Promise),
          URI('https://api.airbrake.io/api/v4/projects/1/deploys')
        )
        described_class.new(user_config.merge(environment: 'fooenv')).
          notify(environment: 'barenv')
      end
    end

    context "when environment is not configured" do
      it "sets the environment from the config" do
        expect_any_instance_of(Airbrake::SyncSender).to receive(:send).with(
          { environment: 'fooenv' },
          instance_of(Airbrake::Promise),
          URI('https://api.airbrake.io/api/v4/projects/1/deploys')
        )
        described_class.new(user_config.merge(environment: 'fooenv')).
          notify({})
      end
    end
  end
end
