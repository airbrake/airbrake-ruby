RSpec.describe Airbrake::ThreadPool do
  subject(:thread_pool) do
    described_class.new(
      worker_size: worker_size,
      queue_size: queue_size,
      block: proc { |message| tasks << message },
    )
  end

  let(:tasks) { [] }
  let(:worker_size) { 1 }
  let(:queue_size) { 2 }

  describe "#<<" do
    it "returns true" do
      retval = thread_pool << 1
      thread_pool.close
      expect(retval).to eq(true)
    end

    it "performs work in background" do
      thread_pool << 2
      thread_pool << 1
      thread_pool.close

      expect(tasks).to eq([2, 1])
    end

    context "when the queue is full" do
      subject(:full_thread_pool) do
        described_class.new(
          worker_size: 1,
          queue_size: 1,
          block: proc { |message| tasks << message },
        )
      end

      before do
        # rubocop:disable RSpec/SubjectStub
        allow(full_thread_pool).to receive(:backlog).and_return(queue_size)
        # rubocop:enable RSpec/SubjectStub
      end

      it "returns false" do
        retval = full_thread_pool << 1
        full_thread_pool.close
        expect(retval).to eq(false)
      end

      it "discards tasks" do
        200.times { full_thread_pool << 1 }
        full_thread_pool.close

        expect(tasks.size).to be_zero
      end

      it "logs discarded tasks" do
        allow(Airbrake::Loggable.instance).to receive(:info)

        15.times { full_thread_pool << 1 }
        full_thread_pool.close

        expect(Airbrake::Loggable.instance)
          .to have_received(:info).exactly(15).times
      end
    end
  end

  describe "#backlog" do
    let(:worker_size) { 0 }

    it "returns the size of the queue" do
      thread_pool << 1
      expect(thread_pool.backlog).to eq(1)
    end
  end

  describe "#has_workers?" do
    it "returns false when the thread pool is not closed, but has 0 workers" do
      thread_pool.workers.list.each do |worker|
        worker.kill.join
      end
      expect(thread_pool).not_to have_workers
    end

    it "returns false when the thread pool is closed" do
      thread_pool.close
      expect(thread_pool).not_to have_workers
    end

    describe "forking behavior" do
      before do
        skip('fork() is unsupported on JRuby') if %w[jruby].include?(RUBY_ENGINE)
        unless Process.respond_to?(:last_status)
          skip('Process.last_status is unsupported on this Ruby')
        end
      end

      # rubocop:disable RSpec/MultipleExpectations
      it "respawns workers on fork()" do
        pid = fork { expect(thread_pool).to have_workers }
        Process.wait(pid)
        thread_pool.close

        expect(Process.last_status).to be_success
        expect(thread_pool).not_to have_workers
      end
      # rubocop:enable RSpec/MultipleExpectations

      it "ensures that a new thread group is created per process" do
        thread_pool << 1
        pid = fork { thread_pool.has_workers? }
        Process.wait(pid)
        thread_pool.close

        expect(Process.last_status).to be_success
      end
    end
  end

  describe "#close" do
    context "when there's no work to do" do
      it "joins the spawned thread" do
        workers = thread_pool.workers.list
        expect(workers).to all(be_alive)

        thread_pool.close
        expect(workers).to all(be_stop)
      end
    end

    context "when there's some work to do" do
      it "logs how many tasks are left to process" do
        allow(Airbrake::Loggable.instance).to receive(:debug)

        thread_pool = described_class.new(
          name: 'foo', worker_size: 0, queue_size: 2, block: proc {},
        )

        2.times { thread_pool << 1 }
        thread_pool.close

        expect(Airbrake::Loggable.instance).to have_received(:debug).with(
          /waiting to process \d+ task\(s\)/,
        )
        expect(Airbrake::Loggable.instance).to have_received(:debug).with(/foo.+closed/)
      end

      it "waits until the queue gets empty" do
        thread_pool = described_class.new(
          worker_size: 1, queue_size: 2, block: proc {},
        )

        10.times { thread_pool << 1 }
        thread_pool.close
        expect(thread_pool.backlog).to be_zero
      end
    end

    context "when it was already closed" do
      it "doesn't increase the queue size" do
        begin
          thread_pool.close
        rescue Airbrake::Error
          nil
        end

        expect(thread_pool.backlog).to be_zero
      end

      it "raises error" do
        thread_pool.close
        expect { thread_pool.close }.to raise_error(
          Airbrake::Error, 'this thread pool is closed already'
        )
      end
    end
  end

  describe "#spawn_workers" do
    after { thread_pool.close }

    it "spawns an enclosed thread group" do
      expect(thread_pool.workers).to be_a(ThreadGroup)
      expect(thread_pool.workers).to be_enclosed
    end

    it "spawns threads that are alive" do
      expect(thread_pool.workers.list).to all(be_alive)
    end

    it "spawns exactly `workers_size` workers" do
      expect(thread_pool.workers.list.size).to eq(worker_size)
    end
  end
end
