require 'spec_helper'

RSpec.describe Airbrake::Filters::GitRepositoryFilter do
  subject { described_class.new('.') }

  let(:notice) do
    Airbrake::Notice.new(Airbrake::Config.new, AirbrakeTestError.new)
  end

  context "when context/repository is defined" do
    it "doesn't attach anything to context/repository" do
      notice[:context][:repository] = 'git@github.com:kyrylo/test.git'
      subject.call(notice)
      expect(notice[:context][:repository]).to eq('git@github.com:kyrylo/test.git')
    end
  end

  context "when .git directory doesn't exist" do
    subject { described_class.new('root/dir') }

    it "doesn't attach anything to context/repository" do
      subject.call(notice)
      expect(notice[:context][:repository]).to be_nil
    end
  end

  context "when .git directory exists" do
    it "attaches context/repository" do
      subject.call(notice)
      expect(notice[:context][:repository]).to eq(
        'ssh://git@github.com/airbrake/airbrake-ruby.git'
      )
    end
  end
end
