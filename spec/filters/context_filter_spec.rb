require 'spec_helper'

RSpec.describe Airbrake::Filters::ContextFilter do
  let(:notice) do
    Airbrake::Notice.new(Airbrake::Config.new, AirbrakeTestError.new)
  end

  context "when the current context is empty" do
    it "doesn't merge anything with params" do
      described_class.new({}).call(notice)
      expect(notice[:params]).to be_empty
    end
  end

  context "when the current context has some data" do
    it "merges the data with params" do
      described_class.new(apples: 'oranges').call(notice)
      expect(notice[:params]).to eq(airbrake_context: { apples: 'oranges' })
    end

    it "clears the data from the provided context" do
      context = { apples: 'oranges' }
      described_class.new(context).call(notice)
      expect(context).to be_empty
    end
  end
end
