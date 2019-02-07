RSpec.describe Airbrake do
  describe ".[]" do
    it "returns a NilNotifier" do
      expect(described_class[:test]).to be_an(Airbrake::NilNoticeNotifier)
    end
  end

  describe ".notifiers" do
    it "returns a Hash of notifiers" do
      expect(described_class.notifiers).to eq(
        notice: {}, performance: {}, deploy: {}
      )
    end
  end

  let(:default_notifier) do
    described_class[:default]
  end

  describe ".configure" do
    let(:config_params) { { project_id: 1, project_key: 'abc' } }

    after do
      described_class.instance_variable_get(:@notice_notifiers).clear
      described_class.instance_variable_get(:@performance_notifiers).clear
      described_class.instance_variable_get(:@deploy_notifiers).clear
    end

    it "yields the config" do
      expect do |b|
        begin
          described_class.configure(&b)
        rescue Airbrake::Error
          nil
        end
      end.to yield_with_args(Airbrake::Config)
    end

    context "when invoked with a notice notifier name" do
      it "sets notice notifier name to the provided name" do
        described_class.configure(:test) { |c| c.merge(config_params) }
        expect(described_class[:test]).to be_an(Airbrake::NoticeNotifier)
      end
    end

    context "when invoked without a notifier name" do
      it "defaults to the :default notifier name" do
        described_class.configure { |c| c.merge(config_params) }
        expect(described_class[:default]).to be_an(Airbrake::NoticeNotifier)
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

    context "when user config doesn't contain a project id" do
      it "raises error" do
        expect { described_class.configure { |c| c.project_key = '1' } }.
          to raise_error(Airbrake::Error, ':project_id is required')
      end
    end

    context "when user config doesn't contain a project key" do
      it "raises error" do
        expect { described_class.configure { |c| c.project_id = 1 } }.
          to raise_error(Airbrake::Error, ':project_key is required')
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
    let(:default_notifier) { described_class.notifiers[:deploy][:default] }

    it "calls 'notify' on the deploy notifier" do
      expect(default_notifier).to receive(:notify).with(foo: 'bar')
      described_class.create_deploy(foo: 'bar')
    end
  end

  describe ".merge_context" do
    it "forwards 'merge_context' to the notifier" do
      expect(default_notifier).to receive(:merge_context).with(foo: 'bar')
      described_class.merge_context(foo: 'bar')
    end
  end

  describe ".notify_request" do
    let(:default_notifier) { described_class.notifiers[:performance][:default] }

    it "calls 'notify' on the route notifier" do
      params = {
        method: 'GET',
        route: '/foo',
        status_code: 200,
        start_time: Time.new(2018, 1, 1, 0, 20, 0, 0),
        end_time: Time.new(2018, 1, 1, 0, 19, 0, 0)
      }
      expect(default_notifier).to receive(:notify).with(Airbrake::Request.new(params))
      described_class.notify_request(params)
    end
  end

  describe ".notify_query" do
    let(:default_notifier) { described_class.notifiers[:performance][:default] }

    it "calls 'notify' on the query notifier" do
      params = {
        method: 'GET',
        route: '/foo',
        query: 'SELECT * FROM foos',
        start_time: Time.new(2018, 1, 1, 0, 20, 0, 0),
        end_time: Time.new(2018, 1, 1, 0, 19, 0, 0)
      }
      expect(default_notifier).to receive(:notify).with(Airbrake::Query.new(params))
      described_class.notify_query(params)
    end
  end
end
