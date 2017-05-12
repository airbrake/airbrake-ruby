require 'spec_helper'

RSpec.describe Airbrake::Filters::SystemExitFilter do
  it "marks SystemExit exceptions as ignored" do
    notice = Airbrake::Notice.new(Airbrake::Config.new, SystemExit.new)
    expect { subject.call(notice) }.to(
      change { notice.ignored? }.from(false).to(true)
    )
  end

  it "doesn't mark non SystemExit exceptions as ignored" do
    notice = Airbrake::Notice.new(Airbrake::Config.new, AirbrakeTestError.new)
    expect(notice).not_to be_ignored
    expect { subject.call(notice) }.not_to(change { notice.ignored? })
  end
end
