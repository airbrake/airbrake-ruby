RSpec.describe Airbrake::Filters::GitLastCheckoutFilter do
  subject(:git_last_checkout_filter) { described_class.new('.') }

  let(:notice) { Airbrake::Notice.new(AirbrakeTestError.new) }
  let(:git_path) { subject.instance_variable_get(:@git_path) }
  let(:head_path) { "#{git_path}/logs/HEAD" }
  let(:git_info) do
    OpenStruct.new(
      name: 'Arthur',
      email: 'arthur@airbrake.io',
      last_revision: 'ab12' * 10, # must be 40 chars long
    )
  end
  let(:line_one) do
    "asdf2345 #{git_info.last_revision} #{git_info.name} <#{git_info.email}> 1679087797 -0700\tclone: from github.com:my_user/fun_repo.git"
  end
  let(:line_two) do
    "#{git_info.last_revision} dfgh3456 #{git_info.name} <#{git_info.email}> 1679087824 -0700\tpush: moving from main to spike-5"
  end

  before do
    allow(File).to receive(:exists?).with(git_path).and_return(true)
    allow(File).to receive(:exists?).with(head_path).and_return(true)
    allow(File).to receive(:foreach).with(head_path)
      .and_yield(line_one)
      .and_yield(line_two)
  end

  context "when context/lastCheckout is defined" do
    it "doesn't attach anything to context/lastCheckout" do
      notice[:context][:lastCheckout] = '123'
      git_last_checkout_filter.call(notice)
      expect(notice[:context][:lastCheckout]).to eq('123')
    end
  end

  context "when .git directory doesn't exist" do
    subject(:git_last_checkout_without_git_dir_filter) { described_class.new('root/dir') }

    before do
      allow(File).to receive(:exists?).with(git_path).and_return(false)
    end

    it "doesn't attach anything to context/lastCheckout" do
      git_last_checkout_without_git_dir_filter.call(notice)
      expect(notice[:context][:lastCheckout]).to be_nil
    end
  end

  context "when .git directory exists" do
    context "when AIRBRAKE_DEPLOY_USERNAME env variable is set" do
      before do
        ENV['AIRBRAKE_DEPLOY_USERNAME'] = 'deployer'
      end

      it "attaches username from the environment" do
        # reinitialize since username is dependent on env
        described_class.new('.').call(notice)
        expect(notice[:context][:lastCheckout][:username]).to eq('deployer')
      end
    end

    context "when AIRBRAKE_DEPLOY_USERNAME env variable is NOT set" do
      before { ENV['AIRBRAKE_DEPLOY_USERNAME'] = nil }

      it "attaches last checkouted username" do
        # reinitialize since username is dependent on env
        described_class.new('.').call(notice)
        username = notice[:context][:lastCheckout][:username]
        expect(username).to eq(git_info.name)
        expect(username).not_to be_empty
        expect(username).not_to be_nil
      end
    end

    it "attaches last checkouted email" do
      git_last_checkout_filter.call(notice)
      expect(notice[:context][:lastCheckout][:email]).to(match(/\A\w+@[\w\-.]+\z/))
    end

    it "attaches last checkouted revision" do
      git_last_checkout_filter.call(notice)
      expect(notice[:context][:lastCheckout][:revision]).to eq(git_info.last_revision)
      expect(notice[:context][:lastCheckout][:revision]).not_to be_empty
      expect(notice[:context][:lastCheckout][:revision].size).to eq(40)
    end

    it "attaches last checkouted time" do
      git_last_checkout_filter.call(notice)
      expect(notice[:context][:lastCheckout][:time]).not_to be_empty
      expect(notice[:context][:lastCheckout][:time].size).to eq(25)
    end
  end
end
