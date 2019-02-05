RSpec.describe Airbrake::DeployNotifier do
  let(:user_params) { { project_id: 1, project_key: 'banana' } }
  let(:params) { {} }
  let(:config) { Airbrake::Config.new(user_params.merge(params)) }

  subject { described_class.new(config) }

  describe "#notify" do
    it "returns a promise" do
      stub_request(:post, 'https://api.airbrake.io/api/v4/projects/1/deploys').
        to_return(status: 201, body: '{}')
      expect(subject.notify({})).to be_an(Airbrake::Promise)
    end

    context "when environment is configured" do
      let(:params) { { environment: 'fooenv' } }

      it "prefers the passed environment to the config env" do
        expect_any_instance_of(Airbrake::SyncSender).to receive(:send).with(
          { environment: 'barenv' },
          instance_of(Airbrake::Promise),
          URI('https://api.airbrake.io/api/v4/projects/1/deploys')
        )
        subject.notify(environment: 'barenv')
      end
    end

    context "when environment is not configured" do
      let(:params) { { environment: 'fooenv' } }

      it "sets the environment from the config" do
        expect_any_instance_of(Airbrake::SyncSender).to receive(:send).with(
          { environment: 'fooenv' },
          instance_of(Airbrake::Promise),
          URI('https://api.airbrake.io/api/v4/projects/1/deploys')
        )
        subject.notify({})
      end
    end
  end
end
