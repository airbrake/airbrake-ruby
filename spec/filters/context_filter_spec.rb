RSpec.describe Airbrake::Filters::ContextFilter do
  let(:notice) { Airbrake::Notice.new(AirbrakeTestError.new) }

  context "when the current context is empty" do
    it "doesn't merge anything with params" do
      described_class.new.call(notice)
      expect(notice[:params]).to be_empty
    end
  end

  context "when the current context has some data" do
    it "merges the data with params" do
      Airbrake.merge_context(apples: 'oranges')
      described_class.new.call(notice)
      expect(notice[:params]).to eq(airbrake_context: { apples: 'oranges' })
    end

    it "clears the data from the current context" do
      context = { apples: 'oranges' }
      Airbrake.merge_context(context)
      described_class.new.call(notice)
      expect(Airbrake::Context.current).to be_empty
    end

    it "does not mutate the provided context object" do
      context = { apples: 'oranges' }
      Airbrake.merge_context(context)
      described_class.new.call(notice)
      expect(context).to match(apples: 'oranges')
    end
  end
end
