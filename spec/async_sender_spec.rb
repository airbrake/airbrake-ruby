RSpec.describe Airbrake::AsyncSender do
  let(:endpoint) { 'https://api.airbrake.io/api/v3/projects/1/notices' }
  let(:queue_size) { 10 }
  let(:notice) { Airbrake::Notice.new(AirbrakeTestError.new) }

  before do
    stub_request(:post, endpoint).to_return(status: 201, body: '{}')
    Airbrake::Config.instance = Airbrake::Config.new(
      project_id: '1',
      workers: 3,
      queue_size: queue_size
    )

    allow(Airbrake::Loggable.instance).to receive(:debug)
    expect(subject).to have_workers
  end

  describe "#send" do
    it "sends payload to Airbrake" do
      2.times do
        subject.send(notice, Airbrake::Promise.new)
      end
      subject.close

      expect(a_request(:post, endpoint)).to have_been_made.twice
    end

    context "when the queue is full" do
      before do
        allow(subject.unsent).to receive(:size).and_return(queue_size)
      end

      it "discards payload" do
        200.times do
          subject.send(notice, Airbrake::Promise.new)
        end
        subject.close

        expect(a_request(:post, endpoint)).not_to have_been_made
      end

      it "logs discarded payload" do
        expect(Airbrake::Loggable.instance).to receive(:error).with(
          /reached its capacity/
        ).exactly(15).times

        15.times do
          subject.send(notice, Airbrake::Promise.new)
        end
        subject.close
      end

      it "returns a rejected promise" do
        promise = Airbrake::Promise.new
        200.times { subject.send(notice, promise) }
        expect(promise.value).to eq(
          'error' => "AsyncSender has reached its capacity of #{queue_size}"
        )
      end
    end
  end

  describe "#close" do
    context "when there are no unsent notices" do
      it "joins the spawned thread" do
        workers = subject.workers.list
        expect(workers).to all(be_alive)

        subject.close
        expect(workers).to all(be_stop)
      end
    end

    context "when there are some unsent notices" do
      it "logs how many notices are left to send" do
        expect(Airbrake::Loggable.instance).to receive(:debug).with(
          /waiting to send \d+ unsent notice\(s\)/
        )
        expect(Airbrake::Loggable.instance).to receive(:debug).with(/closed/)

        300.times { subject.send(notice, Airbrake::Promise.new) }
        subject.close
      end

      it "waits until the unsent notices queue is empty" do
        subject.close
        expect(subject.unsent.size).to be_zero
      end
    end

    context "when it was already closed" do
      it "doesn't increase the unsent queue size" do
        begin
          subject.close
        rescue Airbrake::Error
          nil
        end

        expect(subject.unsent.size).to be_zero
      end

      it "raises error" do
        subject.close

        expect(subject).to be_closed
        expect { subject.close }.to raise_error(
          Airbrake::Error, 'attempted to close already closed sender'
        )
      end
    end

    context "when workers were not spawned" do
      it "correctly closes the notifier nevertheless" do
        subject.close
        expect(subject).to be_closed
      end
    end
  end

  describe "#has_workers?" do
    it "returns false when the sender is not closed, but has 0 workers" do
      subject.workers.list.each do |worker|
        worker.kill.join
      end
      expect(subject).not_to have_workers
    end

    it "returns false when the sender is closed" do
      subject.close
      expect(subject).not_to have_workers
    end

    it "respawns workers on fork()", skip: %w[jruby rbx].include?(RUBY_ENGINE) do
      pid = fork { expect(subject).to have_workers }
      Process.wait(pid)
      subject.close
      expect(subject).not_to have_workers
    end
  end

  describe "#spawn_workers" do
    it "spawns alive threads in an enclosed ThreadGroup" do
      expect(subject.workers).to be_a(ThreadGroup)
      expect(subject.workers.list).to all(be_alive)
      expect(subject.workers).to be_enclosed

      subject.close
    end

    it "spawns exactly config.workers workers" do
      expect(subject.workers.list.size).to eq(Airbrake::Config.instance.workers)
      subject.close
    end
  end
end
