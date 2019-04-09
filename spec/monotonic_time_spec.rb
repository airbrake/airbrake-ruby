RSpec.describe Airbrake::MonotonicTime do
  describe ".time_in_ms" do
    it "returns monotonic time in milliseconds" do
      expect(subject.time_in_ms).to be_a(Float)
    end

    it "always returns time in the future" do
      old_time = subject.time_in_ms
      expect(subject.time_in_ms).to be > old_time
    end
  end
end
