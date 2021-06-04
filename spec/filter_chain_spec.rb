RSpec.describe Airbrake::FilterChain do
  subject(:filter_chain) { described_class.new }

  let(:notice) { Airbrake::Notice.new(AirbrakeTestError.new) }

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

      (0...3).reverse_each { |i| filter_chain.add_filter(filter.new(i)) }
      filter_chain.refine(notice)

      expect(notice[:params][:bingo]).to eq([2, 1, 0])
    end

    it "stops execution once a notice was ignored" do
      f2 = filter.new(2)
      allow(f2).to receive(:call)

      f1 = proc { |notice| notice.ignore! }

      f0 = filter.new(-1)
      allow(f0).to receive(:call)

      [f2, f1, f0].each { |f| filter_chain.add_filter(f) }

      filter_chain.refine(notice)

      expect(f2).to have_received(:call)
      expect(f0).not_to have_received(:call)
    end
  end

  describe "#delete_filter" do
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

    it "deletes a class filter" do
      notice[:params][:foo] = []

      f1 = filter.new(1)
      filter_chain.add_filter(f1)

      foo_filter_mock = double
      allow(foo_filter_mock).to receive(:name).at_least(:once).and_return('FooFilter')
      filter_chain.delete_filter(foo_filter_mock)

      expect(foo_filter_mock).to have_received(:name)

      f2 = filter.new(2)
      filter_chain.add_filter(f2)

      filter_chain.refine(notice)
      expect(notice[:params][:foo]).to eq([2])
    end
  end

  describe "#inspect" do
    it "returns a string representation of an empty FilterChain" do
      expect(filter_chain.inspect).to eq('[]')
    end

    it "returns a string representation of a non-empty FilterChain" do
      filter_chain.add_filter(proc {})
      expect(filter_chain.inspect).to eq('[Proc]')
    end
  end

  describe "#includes?" do
    context "when a custom filter class is included in the filter chain" do
      it "returns true" do
        klass = Class.new

        filter_chain.add_filter(klass.new)
        expect(filter_chain.includes?(klass)).to eq(true)
      end
    end

    context "when Proc filter class is included in the filter chain" do
      it "returns true" do
        filter_chain.add_filter(proc {})
        expect(filter_chain.includes?(Proc)).to eq(true)
      end
    end

    context "when filter class is NOT included in the filter chain" do
      it "returns false" do
        klass = Class.new

        filter_chain.add_filter(proc {})
        expect(filter_chain.includes?(klass)).to eq(false)
      end
    end
  end
end
