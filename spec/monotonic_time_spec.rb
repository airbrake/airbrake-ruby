RSpec.describe Airbrake::MonotonicTime do
  subject(:monotonic_time) { described_class }

  describe ".time_in_ms" do
    it "returns monotonic time in milliseconds" do
      expect(monotonic_time.time_in_ms).to be_a(Float)
    end

    it "always returns time in the future" do
      old_time = monotonic_time.time_in_ms
      expect(monotonic_time.time_in_ms).to be > old_time
    end
  end

  describe ".time_in_s" do
    it "returns monotonic time in seconds" do
      expect(monotonic_time.time_in_s).to be_a(Float)
    end

    it "always returns time in the future" do
      old_time = monotonic_time.time_in_s
      expect(monotonic_time.time_in_s).to be > old_time
    end
  end
end
