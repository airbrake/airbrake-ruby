RSpec.describe Airbrake::Backlog do
  subject(:backlog) { described_class.new(sync_sender, 0.1) }

  let(:sync_sender) { Airbrake::SyncSender.new }
  let(:error_endpoint) { '/error' }
  let(:event_endpoint) { '/event' }
  let(:promise) { an_instance_of(Airbrake::Promise) }

  before { allow(sync_sender).to receive(:send) }

  after { backlog.close }

  describe "#<<" do
    it "returns self" do
      expect(backlog << 1).to eq(backlog)
    end

    it "waits for the data to be processed" do
      backlog << [1, error_endpoint] << [2, event_endpoint]

      expect(sync_sender).not_to have_received(:send)
        .with(1, promise, error_endpoint)
      expect(sync_sender).not_to have_received(:send)
        .with(2, promise, event_endpoint)
    end

    it "processed the data on flush" do
      backlog << [1, error_endpoint] << [2, event_endpoint]

      sleep 0.2

      expect(sync_sender).to have_received(:send)
        .with(1, promise, error_endpoint)
      expect(sync_sender).to have_received(:send)
        .with(2, promise, event_endpoint)
    end

    it "clears the queue after flushing" do
      backlog << [1, error_endpoint] << [2, event_endpoint]

      sleep 0.2

      backlog << [3, event_endpoint] << [4, error_endpoint]

      sleep 0.2

      expect(sync_sender).to have_received(:send)
        .with(3, promise, event_endpoint)
      expect(sync_sender).to have_received(:send)
        .with(4, promise, error_endpoint)
    end

    it "doesn't append an already appended item" do
      backlog << [1, error_endpoint] << [1, error_endpoint] << [1, error_endpoint]

      sleep 0.2

      expect(sync_sender).to have_received(:send)
        .with(1, promise, error_endpoint).once
    end

    context "when then backlog reaches its capacity of 100" do
      before { allow(Airbrake::Loggable.instance).to receive(:error) }

      it "logs errors" do
        102.times { |i| backlog << [i, error_endpoint] }

        sleep 0.2

        expect(Airbrake::Loggable.instance).to have_received(:error).with(
          '**Airbrake: Airbrake::Backlog full',
        ).twice
      end
    end
  end
end
