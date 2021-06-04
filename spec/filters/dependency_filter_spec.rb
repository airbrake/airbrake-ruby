RSpec.describe Airbrake::Filters::DependencyFilter do
  subject(:dependency_filter) { described_class.new }

  let(:notice) { Airbrake::Notice.new(AirbrakeTestError.new) }

  describe "#call" do
    it "attaches loaded dependencies to context/versions/dependencies" do
      dependency_filter.call(notice)
      expect(notice[:context][:versions][:dependencies]).to include(
        'airbrake-ruby' => Airbrake::AIRBRAKE_RUBY_VERSION,
      )
    end
  end
end
