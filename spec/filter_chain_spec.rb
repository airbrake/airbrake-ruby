require 'spec_helper'

RSpec.describe Airbrake::FilterChain do
  before do
    @chain = described_class.new(config, thread_context)
  end

  let(:config) { Airbrake::Config.new }
  let(:thread_context) { Airbrake::ThreadContext.new('bingo') }

  describe "#refine" do
    let(:notice) { Airbrake::Notice.new(config, AirbrakeTestError.new) }

    describe "execution order" do
      it "executes filters starting from the oldest" do
        nums = []

        3.times do |i|
          @chain.add_filter(proc { nums << i })
        end

        @chain.refine(notice)

        expect(nums).to eq([0, 1, 2])
      end

      it "stops execution once a notice was ignored" do
        nums = []

        5.times do |i|
          @chain.add_filter(proc do |notice|
                              nums << i
                              notice.ignore! if i == 2
                            end)
        end

        @chain.refine(notice)

        expect(nums).to eq([0, 1, 2])
      end

      it "executes keys filters last" do
        notice[:params] = { bingo: 'bango' }
        blacklist = Airbrake::Filters::KeysBlacklist.new(config.logger, :bingo)
        @chain.add_filter(blacklist)

        @chain.add_filter(
          proc do |notice|
            expect(notice[:params][:bingo]).to eq('bango')
          end
        )

        @chain.refine(notice)
        expect(notice[:params][:bingo]).to eq('[Filtered]')
      end
    end

    describe "default backtrace filters" do
      let(:ex) { AirbrakeTestError.new.tap { |e| e.set_backtrace(backtrace) } }
      let(:notice) { Airbrake::Notice.new(config, ex) }

      before do
        Gem.path << '/my/gem/root' << '/my/other/gem/root'
        @chain.refine(notice)
        @bt = notice[:errors].first[:backtrace].map { |frame| frame[:file] }
      end

      shared_examples 'root directories' do |root_directory, bt, expected_bt|
        let(:backtrace) { bt }

        before do
          config = Airbrake::Config.new(root_directory: root_directory)
          chain = described_class.new(config, thread_context)
          chain.refine(notice)
          @bt = notice[:errors].first[:backtrace].map { |frame| frame[:file] }
        end

        it "filters it out" do
          expect(@bt).to eq(expected_bt)
        end
      end

      # rubocop:disable Metrics/LineLength
      context "gem root" do
        bt = [
          "/home/kyrylo/code/airbrake/ruby/spec/spec_helper.rb:23:in `<top (required)>'",
          "/my/gem/root/gems/rspec-core-3.3.2/lib/rspec/core/configuration.rb:1327:in `load'",
          "/opt/rubies/ruby-2.2.2/lib/ruby/2.2.0/rubygems/core_ext/kernel_require.rb:54:in `require'",
          "/my/other/gem/root/gems/rspec-core-3.3.2/exe/rspec:4:in `<main>'"
        ]

        expected_bt = [
          "/home/kyrylo/code/airbrake/ruby/spec/spec_helper.rb",
          "[GEM_ROOT]/gems/rspec-core-3.3.2/lib/rspec/core/configuration.rb",
          "/opt/rubies/ruby-2.2.2/lib/ruby/2.2.0/rubygems/core_ext/kernel_require.rb",
          "[GEM_ROOT]/gems/rspec-core-3.3.2/exe/rspec"
        ]

        include_examples 'root directories', nil, bt, expected_bt
      end

      context "root directory" do
        context "when normal string path" do
          bt = [
            "/home/kyrylo/code/airbrake/ruby/spec/spec_helper.rb:23:in `<top (required)>'",
            "/var/www/project/gems/rspec-core-3.3.2/lib/rspec/core/configuration.rb:1327:in `load'",
            "/opt/rubies/ruby-2.2.2/lib/ruby/2.2.0/rubygems/core_ext/kernel_require.rb:54:in `require'",
            "/var/www/project/gems/rspec-core-3.3.2/exe/rspec:4:in `<main>'"
          ]

          expected_bt = [
            "/home/kyrylo/code/airbrake/ruby/spec/spec_helper.rb",
            "[PROJECT_ROOT]/gems/rspec-core-3.3.2/lib/rspec/core/configuration.rb",
            "/opt/rubies/ruby-2.2.2/lib/ruby/2.2.0/rubygems/core_ext/kernel_require.rb",
            "[PROJECT_ROOT]/gems/rspec-core-3.3.2/exe/rspec"
          ]

          include_examples 'root directories', '/var/www/project', bt, expected_bt
        end

        context "when equals to a part of filename" do
          bt = [
            "/home/kyrylo/code/airbrake/ruby/spec/spec_helper.rb:23:in `<top (required)>'",
            "/var/www/gems/gems/rspec-core-3.3.2/lib/rspec/core/configuration.rb:1327:in `load'",
            "/opt/rubies/ruby-2.2.2/lib/ruby/2.2.0/rubygems/core_ext/kernel_require.rb:54:in `require'",
            "/var/www/gems/gems/rspec-core-3.3.2/exe/rspec:4:in `<main>'"
          ]

          expected_bt = [
            "/home/kyrylo/code/airbrake/ruby/spec/spec_helper.rb",
            "[PROJECT_ROOT]/gems/rspec-core-3.3.2/lib/rspec/core/configuration.rb",
            "/opt/rubies/ruby-2.2.2/lib/ruby/2.2.0/rubygems/core_ext/kernel_require.rb",
            "[PROJECT_ROOT]/gems/rspec-core-3.3.2/exe/rspec"
          ]

          include_examples 'root directories', '/var/www/gems', bt, expected_bt
        end

        context "when normal pathname path" do
          bt = [
            "/home/kyrylo/code/airbrake/ruby/spec/spec_helper.rb:23:in `<top (required)>'",
            "/var/www/project/gems/rspec-core-3.3.2/lib/rspec/core/configuration.rb:1327:in `load'",
            "/opt/rubies/ruby-2.2.2/lib/ruby/2.2.0/rubygems/core_ext/kernel_require.rb:54:in `require'",
            "/var/www/project/gems/rspec-core-3.3.2/exe/rspec:4:in `<main>'"
          ]

          expected_bt = [
            "/home/kyrylo/code/airbrake/ruby/spec/spec_helper.rb",
            "[PROJECT_ROOT]/gems/rspec-core-3.3.2/lib/rspec/core/configuration.rb",
            "/opt/rubies/ruby-2.2.2/lib/ruby/2.2.0/rubygems/core_ext/kernel_require.rb",
            "[PROJECT_ROOT]/gems/rspec-core-3.3.2/exe/rspec"
          ]

          include_examples 'root directories',
                           Pathname.new('/var/www/project'), bt, expected_bt
        end
      end
      # rubocop:enable Metrics/LineLength
    end

    describe "default ignore filters" do
      context "system exit filter" do
        it "marks SystemExit exceptions as ignored" do
          notice = Airbrake::Notice.new(config, SystemExit.new)
          expect { @chain.refine(notice) }.
            to(change { notice.ignored? }.from(false).to(true))
        end
      end

      context "gem root filter" do
        let(:ex) do
          AirbrakeTestError.new.tap do |error|
            error.set_backtrace(['(unparseable/frame.rb:23)'])
          end
        end

        it "does not filter file if it is nil" do
          config.logger = Logger.new('/dev/null')
          notice = Airbrake::Notice.new(config, ex)

          expect(notice[:errors].first[:file]).to be_nil
          expect { @chain.refine(notice) }.
            not_to(change { notice[:errors].first[:file] })
        end
      end

      context "root directory filter" do
        let(:ex) do
          AirbrakeTestError.new.tap do |error|
            error.set_backtrace(['(unparseable/frame.rb:23)'])
          end
        end

        it "does not filter file if it is nil" do
          config.logger = Logger.new('/dev/null')
          config.root_directory = '/bingo/bango'
          notice = Airbrake::Notice.new(config, ex)
          filter_chain = described_class.new(config, thread_context)

          expect(notice[:errors].first[:file]).to be_nil
          expect { filter_chain.refine(notice) }.
            not_to(change { notice[:errors].first[:file] })
        end
      end
    end

    describe "thread context filter" do
      it "adds appends variables to params" do
        thread_context[:bingo] = :bango
        filter_chain = described_class.new(config, thread_context)

        expect(notice[:params][:thread_context]).to be_nil
        filter_chain.refine(notice)
        expect(notice[:params][:thread_context][:bingo]).to eq(:bango)
      end

      it "clears thread context" do
        thread_context[:bingo] = :bango
        @chain.refine(notice)
        expect(thread_context[:bingo]).to be_nil
      end

      it "doesn't append thread context when it's empty" do
        @chain.refine(notice)
        expect(notice[:params][:thread_context]).to be_nil
      end
    end
  end
end
