RSpec.describe Airbrake::Stashable do
  let(:klass) do
    mod = described_class
    Class.new { include(mod) }
  end

  describe "#stash" do
    subject(:instance) { klass.new }

    it "returns a hash" do
      expect(instance.stash).to be_a(Hash)
    end

    it "returns an empty hash" do
      expect(instance.stash).to be_empty
    end

    it "remembers what was put in the stash" do
      instance.stash[:foo] = 1
      expect(instance.stash[:foo]).to eq(1)
    end
  end
end
