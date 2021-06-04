RSpec.describe Airbrake::Filters::SystemExitFilter do
  subject(:system_exit_filter) { described_class.new }

  it "marks SystemExit exceptions as ignored" do
    notice = Airbrake::Notice.new(SystemExit.new)
    expect { system_exit_filter.call(notice) }.to(
      change { notice.ignored? }.from(false).to(true),
    )
  end

  it "doesn't mark non SystemExit exceptions as ignored" do
    notice = Airbrake::Notice.new(AirbrakeTestError.new)
    expect(notice).not_to be_ignored
    expect { system_exit_filter.call(notice) }.not_to(change { notice.ignored? })
  end
end
