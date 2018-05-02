require 'spec_helper'

RSpec.describe Airbrake::Filters::DependencyFilter do
  let(:notice) do
    Airbrake::Notice.new(Airbrake::Config.new, AirbrakeTestError.new)
  end

  describe "#call" do
    it "attaches loaded dependencies to context/versions/dependencies" do
      subject.call(notice)
      expect(notice[:context][:versions][:dependencies]).to include(
        'airbrake-ruby' => Airbrake::AIRBRAKE_RUBY_VERSION
      )
    end
  end
end
