require 'spec_helper'

RSpec.describe Airbrake do
  let(:endpoint) do
    'https://airbrake.io/api/v3/projects/113743/notices?key=fd04e13d806a90f96614ad8e529b2822'
  end

  let!(:notifier) do
    described_class.configure do |c|
      c.project_id = 113743
      c.project_key = 'fd04e13d806a90f96614ad8e529b2822'
    end
  end

  before do
    stub_request(:post, endpoint).to_return(status: 201, body: '{}')
  end

  after do
    described_class.instance_variable_set(:@notifiers, {})
  end

  shared_examples 'non-configured notifier handling' do |method|
    it "returns nil if there is no configured notifier when using #{method}" do
      described_class.instance_variable_set(:@notifiers, {})
      expect(described_class.__send__(method, 'bingo')).to be_nil
    end
  end

  describe ".notify" do
    include_examples 'non-configured notifier handling', :notify

    it "sends exceptions asynchronously" do
      described_class.notify('bingo')
      sleep 2
      expect(a_request(:post, endpoint)).to have_been_made.once
    end
  end

  describe ".notify_sync" do
    include_examples 'non-configured notifier handling', :notify_sync

    it "sends exceptions synchronously" do
      expect(described_class.notify_sync('bingo')).to be_a(Hash)
      expect(a_request(:post, endpoint)).to have_been_made.once
    end

    context "given the notifier argument" do
      it "sends exceptions via that notifier, ignoring other ones" do
        bingo_string = StringIO.new
        bango_string = StringIO.new

        described_class.configure(:bingo) do |c|
          c.project_id = 113743
          c.project_key = 'fd04e13d806a90f96614ad8e529b2822'
          c.logger = Logger.new(bingo_string)
        end

        described_class.configure(:bango) do |c|
          c.project_id = 113743
          c.project_key = 'fd04e13d806a90f96614ad8e529b2822'
          c.logger = Logger.new(bango_string)
        end

        stub_request(:post, endpoint).to_return(status: 201, body: '{"id":1}')

        described_class.notify_sync('bango', {}, :bango)
        expect(bingo_string.string).to be_empty
        expect(bango_string.string).to match(/\*\*Airbrake: {"id"=>1}/)
      end
    end

    describe "clean backtrace" do
      shared_examples 'backtrace building' do |msg, argument|
        it(msg) do
          described_class.notify_sync(argument)

          # rubocop:disable Metrics/LineLength
          expected_body = %r|
            {"errors":\[{"type":"RuntimeError","message":"bingo","backtrace":\[
            {"file":"[\w/\-\.]+spec/airbrake_spec.rb","line":\d+,"function":"[\w/\s\(\)<>]+"},
            {"file":"\[GEM_ROOT\]/gems/rspec-core-.+/.+","line":\d+,"function":"[\w/\s\(\)<>]+"}
          |x
          # rubocop:enable Metrics/LineLength

          expect(
            a_request(:post, endpoint).
            with(body: expected_body)
          ).to have_been_made.once
        end
      end

      context "given a String" do
        include_examples(
          'backtrace building',
          'converts it to a RuntimeException and builds a fake backtrace',
          'bingo'
        )
      end

      context "given an Exception with missing backtrace" do
        include_examples(
          'backtrace building',
          'builds a backtrace for it and sends the notice',
          RuntimeError.new('bingo')
        )
      end
    end

    context "special params" do
      it "sends context/component and doesn't contain params/component" do
        described_class.notify_sync('bingo', component: 'bango')

        expect(
          a_request(:post, endpoint).
          with(body: /"context":{.*"component":"bango".+"params":{}/)
        ).to have_been_made.once
      end

      it "sends context/action and doesn't contain params/action" do
        described_class.notify_sync('bingo', action: 'bango')

        expect(
          a_request(:post, endpoint).
          with(body: /"context":{.*"action":"bango".+"params":{}/)
        ).to have_been_made.once
      end
    end
  end

  describe ".configure" do
    context "given an argument" do
      it "configures a notifier with the given name" do
        described_class.configure(:bingo) do |c|
          c.project_id = 123
          c.project_key = '321'
        end

        notifiers = described_class.instance_variable_get(:@notifiers)

        expect(notifiers).to be_a(Hash)
        expect(notifiers.keys).to eq([:default, :bingo])
        expect(notifiers.values).to all(satisfy { |v| v.is_a?(Airbrake::Notifier) })
      end

      it "raises error when a notifier of the given type was already configured" do
        described_class.configure(:bingo) do |c|
          c.project_id = 123
          c.project_key = '321'
        end

        expect do
          described_class.configure(:bingo) do |c|
            c.project_id = 123
            c.project_key = '321'
          end
        end.to raise_error(Airbrake::Error,
                           "the 'bingo' notifier was already configured")
      end
    end
  end

  describe ".add_filter" do
    include_examples 'non-configured notifier handling', :add_filter

    it "adds filters with help of blocks" do
      filter_chain = notifier.instance_variable_get(:@filter_chain)
      filters = filter_chain.instance_variable_get(:@filters)

      expect(filters.size).to eq(2)

      described_class.add_filter {}

      expect(filters.size).to eq(3)
      expect(filters.last).to be_a(Proc)
    end
  end

  describe ".whitelist_keys" do
    include_examples 'non-configured notifier handling', :whitelist_keys
  end

  describe ".blacklist_keys" do
    include_examples 'non-configured notifier handling', :blacklist_keys
  end

  describe ".build_notice" do
    include_examples 'non-configured notifier handling', :build_notice
  end
end
