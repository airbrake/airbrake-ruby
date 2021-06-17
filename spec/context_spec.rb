RSpec.describe Airbrake::Context do
  subject(:context) { described_class.current }

  before { described_class.current.clear }

  after { described_class.current.clear }

  describe "#merge!" do
    it "merges the given context with the current one" do
      context.merge!(apples: 'oranges')
      expect(context.to_h).to match(apples: 'oranges')
    end
  end

  describe "#clear" do
    it "clears the context" do
      context.merge!(apples: 'oranges')
      context.clear
      expect(context.to_h).to be_empty
    end
  end

  describe "#to_h" do
    it "returns a hash representation of the context" do
      expect(context.to_h).to be_a(Hash)
    end
  end

  describe "#empty?" do
    context "when the context has data" do
      it "returns true" do
        context.merge!(apples: 'oranges')
        expect(context).not_to be_empty
      end
    end

    context "when the context has NO data" do
      it "returns false" do
        expect(context).to be_empty
      end
    end
  end

  context "when another thread is spawned" do
    it "doesn't clash with other threads' contexts" do
      described_class.current.merge!(apples: 'oranges')
      th = Thread.new do
        described_class.current.merge!(foos: 'bars')
      end
      th.join
      expect(described_class.current.to_h).to match(apples: 'oranges')
    end
  end
end
