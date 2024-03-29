RSpec.describe Airbrake::TDigest do
  subject(:tdigest) { described_class.new }

  describe "byte serialization" do
    it "loads serialized data" do
      tdigest.push(60, 100)
      10.times { tdigest.push(rand * 100) }
      bytes = tdigest.as_bytes
      new_tdigest = described_class.from_bytes(bytes)
      expect(new_tdigest.percentile(0.9)).to eq(tdigest.percentile(0.9))
      expect(new_tdigest.as_bytes).to eq(bytes)
    end

    it "handles zero size" do
      bytes = tdigest.as_bytes
      expect(described_class.from_bytes(bytes).size).to be_zero
    end

    it "preserves compression" do
      td = described_class.new(0.001)
      bytes = td.as_bytes
      new_tdigest = described_class.from_bytes(bytes)
      expect(new_tdigest.compression).to eq(td.compression)
    end
  end

  describe "small byte serialization" do
    it "loads serialized data" do
      10.times { tdigest.push(10) }
      bytes = tdigest.as_small_bytes
      new_tdigest = described_class.from_bytes(bytes)
      # Expect some rounding error due to compression
      expect(new_tdigest.percentile(0.9).round(5)).to eq(
        tdigest.percentile(0.9).round(5),
      )
      expect(new_tdigest.as_small_bytes).to eq(bytes)
    end

    it "handles zero size" do
      bytes = tdigest.as_small_bytes
      expect(described_class.from_bytes(bytes).size).to be_zero
    end
  end

  describe "JSON serialization" do
    it "loads serialized data" do
      tdigest.push(60, 100)
      json = tdigest.as_json
      new_tdigest = described_class.from_json(json)
      expect(new_tdigest.percentile(0.9)).to eq(tdigest.percentile(0.9))
    end
  end

  describe "#percentile" do
    it "returns nil if empty" do
      expect(tdigest.percentile(0.90)).to be_nil # This should not crash
    end

    it "raises ArgumentError of input not between 0 and 1" do
      expect { tdigest.percentile(1.1) }.to raise_error(ArgumentError)
    end

    describe "with only single value" do
      it "returns the value" do
        tdigest.push(60, 100)
        expect(tdigest.percentile(0.90)).to eq(60)
      end

      it "returns 0 for all percentiles when only 0 present" do
        tdigest.push(0)
        expect(tdigest.percentile([0.0, 0.5, 1.0])).to eq([0, 0, 0])
      end
    end

    describe "with alot of uniformly distributed points" do
      it "has minimal error" do
        seed = srand(1234) # Makes the values a proper fixture
        maxerr = 0
        values = Array.new(100_000).map { rand }
        srand(seed)

        tdigest.push(values)
        tdigest.compress!

        0.step(1, 0.1).each do |i|
          q = tdigest.percentile(i)
          maxerr = [maxerr, (i - q).abs].max
        end

        expect(maxerr).to be < 0.02
      end
    end
  end

  describe "#push" do
    it "does not blow up if data comes in sorted" do
      tdigest.push(0..10_000)
      expect(tdigest.centroids.size).to be < 5_000
      tdigest.compress!
      expect(tdigest.centroids.size).to be < 1_000
    end
  end

  describe "#size" do
    it "reports the number of observations" do
      n = 10_000
      n.times { tdigest.push(rand) }
      tdigest.compress!
      expect(tdigest.size).to eq(n)
    end
  end

  describe "#+" do
    it "works with empty tdigests" do
      other = described_class.new(0.001, 50, 1.2)
      expect((tdigest + other).centroids.size).to eq(0)
    end

    describe "adding two tdigests" do
      let(:other) { described_class.new(0.001, 50, 1.2) }

      before do
        [tdigest, other].each do |td|
          td.push(60, 100)
          10.times { td.push(rand * 100) }
        end
      end

      # rubocop:disable RSpec/MultipleExpectations
      it "has the parameters of the left argument (the calling tdigest)" do
        new_tdigest = tdigest + other
        expect(new_tdigest.instance_variable_get(:@delta)).to eq(
          tdigest.instance_variable_get(:@delta),
        )
        expect(new_tdigest.instance_variable_get(:@k)).to eq(
          tdigest.instance_variable_get(:@k),
        )
        expect(new_tdigest.instance_variable_get(:@cx)).to eq(
          tdigest.instance_variable_get(:@cx),
        )
      end
      # rubocop:enable RSpec/MultipleExpectations

      it "returns a tdigest with less than or equal centroids" do
        new_tdigest = tdigest + other
        expect(new_tdigest.centroids.size)
          .to be <= tdigest.centroids.size + other.centroids.size
      end

      it "has the size of the two digests combined" do
        new_tdigest = tdigest + other
        expect(new_tdigest.size).to eq(tdigest.size + other.size)
      end
    end
  end

  describe "#merge!" do
    it "works with empty tdigests" do
      other = described_class.new(0.001, 50, 1.2)
      tdigest.merge!(other)
      expect(tdigest.centroids.size).to be_zero
    end

    describe "with populated tdigests" do
      let(:other) { described_class.new(0.001, 50, 1.2) }

      before do
        [tdigest, other].each do |td|
          td.push(60, 100)
          10.times { td.push(rand * 100) }
        end
      end

      it "has the parameters of the calling tdigest" do
        vars = %i[@delta @k @cx]
        expected = vars.map { |v| [v, tdigest.instance_variable_get(v)] }.to_h
        tdigest.merge!(other)
        vars.each do |v|
          expect(tdigest.instance_variable_get(v)).to eq(expected[v])
        end
      end

      it "returns a tdigest with less than or equal centroids" do
        combined_size = tdigest.centroids.size + other.centroids.size
        tdigest.merge!(other)
        expect(tdigest.centroids.size).to be <= combined_size
      end

      it "has the size of the two digests combined" do
        combined_size = tdigest.size + other.size
        tdigest.merge!(other)
        expect(tdigest.size).to eq(combined_size)
      end
    end
  end
end
