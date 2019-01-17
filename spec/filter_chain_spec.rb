require 'spec_helper'

RSpec.describe Airbrake::FilterChain do
  subject { described_class.new(config, {}) }

  let(:config) { Airbrake::Config.new }

  let(:notice) do
    Airbrake::Notice.new(config, AirbrakeTestError.new)
  end

  describe "#refine" do
    let(:filter) do
      Class.new do
        attr_reader :weight

        def initialize(weight)
          @weight = weight
        end

        def call(notice)
          notice[:params][:bingo] << @weight
        end
      end
    end

    it "executes filters from heaviest to lightest" do
      notice[:params][:bingo] = []

      (0...3).reverse_each { |i| subject.add_filter(filter.new(i)) }
      subject.refine(notice)

      expect(notice[:params][:bingo]).to eq([2, 1, 0])
    end

    it "stops execution once a notice was ignored" do
      f2 = filter.new(2)
      expect(f2).to receive(:call)

      f1 = proc { |notice| notice.ignore! }

      f0 = filter.new(-1)
      expect(f0).not_to receive(:call)

      [f2, f1, f0].each { |f| subject.add_filter(f) }

      subject.refine(notice)
    end
  end

  describe "#add_filter" do
    let(:filter) do
      Class.new do
        class << self
          def name
            'FooFilter'
          end
        end

        def initialize(foo)
          @foo = foo
        end

        def call(notice)
          notice[:params][:foo] << @foo
        end
      end
    end

    it "replaces old filter with a new one when the same class owns it" do
      notice[:params][:foo] = []

      f1 = filter.new(1)
      subject.add_filter(f1)

      f2 = filter.new(2)
      subject.add_filter(f2)

      subject.refine(notice)

      expect(notice[:params][:foo]).to eq([2])
    end
  end
end
