require 'spec_helper'

RSpec.describe Airbrake::FilterChain do
  before do
    @chain = described_class.new(config)
  end

  let(:config) { Airbrake::Config.new }

  describe "#refine" do
    describe "execution order" do
      let(:notice) do
        Airbrake::Notice.new(config, AirbrakeTestError.new)
      end

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
          chain = described_class.new(config)
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
    end
  end
end
