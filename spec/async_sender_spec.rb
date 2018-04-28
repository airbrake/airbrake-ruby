require 'spec_helper'

RSpec.describe Airbrake::AsyncSender do
  before do
    stub_request(:post, /.*/).to_return(status: 201, body: '{}')
  end

  describe "#send" do
    it "limits the size of the queue" do
      stdout = StringIO.new
      notices_count = 1000
      queue_size = 10
      config = Airbrake::Config.new(
        logger: Logger.new(stdout), workers: 3, queue_size: queue_size
      )
      sender = described_class.new(config)
      expect(sender).to have_workers

      notice = Airbrake::Notice.new(config, AirbrakeTestError.new)
      notices_count.times { sender.send(notice, Airbrake::Promise.new) }
      sender.close

      log = stdout.string.split("\n")
      notices_sent    = log.grep(/\*\*Airbrake: \{\}/).size
      notices_dropped = log.grep(/\*\*Airbrake:.*not.*delivered/).size
      expect(notices_sent).to be >= queue_size
      expect(notices_sent + notices_dropped).to eq(notices_count)
    end
  end

  describe "#close" do
    before do
      @stderr = StringIO.new
      config = Airbrake::Config.new(logger: Logger.new(@stderr))
      @sender = described_class.new(config)
      expect(@sender).to have_workers
    end

    context "when there are no unsent notices" do
      it "joins the spawned thread" do
        workers = @sender.instance_variable_get(:@workers).list

        expect(workers).to all(be_alive)
        @sender.close
        expect(workers).to all(be_stop)
      end
    end

    context "when there are some unsent notices" do
      before do
        notice = Airbrake::Notice.new(Airbrake::Config.new, AirbrakeTestError.new)
        300.times { @sender.send(notice, Airbrake::Promise.new) }
        expect(@sender.instance_variable_get(:@unsent).size).not_to be_zero
        @sender.close
      end

      it "warns about the number of notices" do
        expect(@stderr.string).to match(/waiting to send \d+ unsent notice/)
      end

      it "prints the correct number of log messages" do
        log = @stderr.string.split("\n")
        notices_sent    = log.grep(/\*\*Airbrake: \{\}/).size
        notices_dropped = log.grep(/\*\*Airbrake:.*not.*delivered/).size
        expect(notices_sent).to be >= @sender.instance_variable_get(:@unsent).max
        expect(notices_sent + notices_dropped).to eq(300)
      end

      it "waits until the unsent notices queue is empty" do
        expect(@sender.instance_variable_get(:@unsent).size).to be_zero
      end
    end

    context "when it was already closed" do
      it "doesn't increase the unsent queue size" do
        begin
          @sender.close
        rescue Airbrake::Error
          nil
        end

        expect(@sender.instance_variable_get(:@unsent).size).to be_zero
      end

      it "raises error" do
        @sender.close

        expect(@sender).to be_closed
        expect { @sender.close }.
          to raise_error(Airbrake::Error, 'attempted to close already closed sender')
      end
    end

    context "when workers were not spawned" do
      it "correctly closes the notifier nevertheless" do
        sender = described_class.new(Airbrake::Config.new)
        sender.close

        expect(sender).to be_closed
      end
    end
  end

  describe "#has_workers?" do
    before do
      @sender = described_class.new(Airbrake::Config.new)
      expect(@sender).to have_workers
    end

    it "returns false when the sender is not closed, but has 0 workers" do
      @sender.instance_variable_get(:@workers).list.each(&:kill)
      sleep 1
      expect(@sender).not_to have_workers
    end

    it "returns false when the sender is closed" do
      @sender.close
      expect(@sender).not_to have_workers
    end

    it "respawns workers on fork()", skip: %w[jruby rbx].include?(RUBY_ENGINE) do
      pid = fork do
        expect(@sender).to have_workers
      end
      Process.wait(pid)
      @sender.close
      expect(@sender).not_to have_workers
    end
  end

  describe "#spawn_workers" do
    it "spawns alive threads in an enclosed ThreadGroup" do
      sender = described_class.new(Airbrake::Config.new)
      expect(sender).to have_workers

      workers = sender.instance_variable_get(:@workers)

      expect(workers).to be_a(ThreadGroup)
      expect(workers.list).to all(be_alive)
      expect(workers).to be_enclosed

      sender.close
    end

    it "spawns exactly config.workers workers" do
      workers_count = 5
      sender = described_class.new(Airbrake::Config.new(workers: workers_count))
      expect(sender).to have_workers

      workers = sender.instance_variable_get(:@workers)

      expect(workers.list.size).to eq(workers_count)
      sender.close
    end
  end
end
