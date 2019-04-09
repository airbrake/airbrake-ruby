RSpec.describe Airbrake::Benchmark do
  describe ".measure" do
    it "returns measured performance time" do
      expect(subject.measure { '10' * 10 }).to be_kind_of(Numeric)
    end
  end
end
