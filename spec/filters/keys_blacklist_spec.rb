require 'spec_helper'

RSpec.describe Airbrake::Filters::KeysBlacklist do
  subject do
    described_class.new(Logger.new('/dev/null'), patterns)
  end

  describe "#call" do
    let(:notice) do
      Airbrake::Notice.new(Airbrake::Config.new, AirbrakeTestError.new)
    end

    context "when a pattern is a regexp and when a key is a hash" do
      let(:patterns) { [/bango/] }

      it "doesn't fail" do
        notice[:params] = { bingo: { {} => 'unfiltered' } }
        expect { subject.call(notice) }.not_to raise_error
      end
    end
  end
end
