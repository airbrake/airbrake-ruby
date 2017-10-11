require 'spec_helper'

RSpec.describe Airbrake::FileCache do
  after do
    %i[banana mango].each { |k| described_class.delete(k) }
    expect(described_class).to be_empty
  end

  describe ".[]=" do
    context "when cache limit isn't reached" do
      before do
        stub_const("#{described_class.name}::MAX_SIZE", 10)
      end

      it "adds objects" do
        described_class[:banana] = 1
        described_class[:mango] = 2

        expect(described_class[:banana]).to eq(1)
        expect(described_class[:mango]).to eq(2)
      end
    end

    context "when cache limit is reached" do
      before do
        stub_const("#{described_class.name}::MAX_SIZE", 1)
      end

      it "replaces old objects with new ones" do
        described_class[:banana] = 1
        described_class[:mango] = 2

        expect(described_class[:banana]).to be_nil
        expect(described_class[:mango]).to eq(2)
      end
    end
  end
end
