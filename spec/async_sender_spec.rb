require 'spec_helper'

RSpec.describe Airbrake::AsyncSender do
  before do
    stub_request(:post, /.*/).to_return(status: 201, body: '{}')
    @sender = described_class.new(Airbrake::Config.new)
    @workers = @sender.instance_variable_get(:@workers)
  end

  describe "#new" do
    context "workers_count parameter" do
      let(:new_workers) { 5 }
      let(:config) { Airbrake::Config.new(workers: new_workers) }

      it "spawns alive threads in an enclosed ThreadGroup" do
        expect(@workers).to be_a(ThreadGroup)
        expect(@workers.list).to all(be_alive)
        expect(@workers).to be_enclosed
      end

      it "controls the number of spawned threads" do
        expect(@workers.list.size).to eq(1)

        sender = described_class.new(config)
        workers = sender.instance_variable_get(:@workers)

        expect(workers.list.size).to eq(new_workers)
        sender.close
      end
    end

    context "queue" do
      before do
        @stdout = StringIO.new
      end

      let(:notices) { 1000 }

      let(:config) do
        Airbrake::Config.new(logger: Logger.new(@stdout), workers: 3, queue_size: 10)
      end

      it "limits the size of the queue, but still sends all notices" do
        sender = described_class.new(config)

        notices.times { |i| sender.send(i) }
        sender.close

        log = @stdout.string.split("\n")
        expect(log.grep(/\*\*Airbrake: \{\}/).size).to eq(notices)
      end
    end
  end

  describe "#close" do
    before do
      @stderr = StringIO.new
      config = Airbrake::Config.new(logger: Logger.new(@stderr))
      @sender = described_class.new(config)
      @workers = @sender.instance_variable_get(:@workers).list
    end

    context "when there are no unsent notices" do
      it "joins the spawned thread" do
        expect(@workers).to all(be_alive)
        @sender.close
        expect(@workers).to all(be_stop)
      end
    end

    context "when there are some unsent notices" do
      before do
        300.times { |i| @sender.send(i) }
        expect(@sender.instance_variable_get(:@unsent).size).not_to be_zero
        @sender.close
      end

      it "warns about the number of notices" do
        expect(@stderr.string).to match(/waiting to send \d+ unsent notice/)
      end

      it "prints the debug message the correct number of times" do
        log = @stderr.string.split("\n")
        expect(log.grep(/\*\*Airbrake: \{\}/).size).to eq(300)
      end

      it "waits until the unsent notices queue is empty" do
        expect(@sender.instance_variable_get(:@unsent).size).to be_zero
      end
    end

    context "when it was already closed" do
      it "doesn't increase the unsent queue size" do
        @sender.close
        expect(@sender.instance_variable_get(:@unsent).size).to be_zero

        expect { @sender.close }.
          to raise_error(Airbrake::Error, 'attempted to close already closed sender')
      end
    end
  end

  describe "#has_workers?" do
    it "returns false when the sender is not closed, but has 0 workers" do
      sender = described_class.new(Airbrake::Config.new)
      expect(sender.has_workers?).to be_truthy

      sender.instance_variable_get(:@workers).list.each(&:kill)
      sleep 1
      expect(sender.has_workers?).to be_falsey
    end

    it "returns false when the sender is closed" do
      sender = described_class.new(Airbrake::Config.new)
      expect(sender.has_workers?).to be_truthy

      sender.close
      expect(sender.has_workers?).to be_falsey
    end
  end
end
