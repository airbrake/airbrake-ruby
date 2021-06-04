RSpec.describe Airbrake::Filters::GitRepositoryFilter do
  subject(:git_repository_filter) { described_class.new('.') }

  let(:notice) do
    Airbrake::Notice.new(Airbrake::Config.new, AirbrakeTestError.new)
  end

  describe "#initialize" do
    it "parses standard git version" do
      allow_any_instance_of(Kernel)
        .to receive(:`).and_return('git version 2.18.0')
      expect { git_repository_filter }.not_to raise_error
    end

    it "parses release candidate git version" do
      allow_any_instance_of(Kernel)
        .to receive(:`).and_return('git version 2.21.0-rc0')
      expect { git_repository_filter }.not_to raise_error
    end

    it "parses git version with brackets" do
      allow_any_instance_of(Kernel)
        .to receive(:`).and_return('git version 2.17.2 (Apple Git-113)')
      expect { git_repository_filter }.not_to raise_error
    end
  end

  context "when context/repository is defined" do
    it "doesn't attach anything to context/repository" do
      notice[:context][:repository] = 'git@github.com:kyrylo/test.git'
      git_repository_filter.call(notice)
      expect(notice[:context][:repository]).to eq('git@github.com:kyrylo/test.git')
    end
  end

  context "when .git directory doesn't exist" do
    git_repository_filter { described_class.new('root/dir') }

    it "doesn't attach anything to context/repository" do
      git_repository_filter.call(notice)
      expect(notice[:context][:repository]).to be_nil
    end
  end

  context "when .git directory exists" do
    it "attaches context/repository" do
      git_repository_filter.call(notice)
      expect(notice[:context][:repository]).to eq(
        'ssh://git@github.com/airbrake/airbrake-ruby.git',
      )
    end
  end

  context "when git is not in PATH" do
    it "does not attach context/repository" do
      ENV['PATH'] = ''
      git_repository_filter.call(notice)
      expect(notice[:context][:repository]).to be_nil
    end
  end
end
