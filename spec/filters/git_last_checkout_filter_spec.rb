RSpec.describe Airbrake::Filters::GitLastCheckoutFilter do
  subject(:git_last_checkout_filter) { described_class.new('.') }

  let(:notice) { Airbrake::Notice.new(AirbrakeTestError.new) }

  context "when context/lastCheckout is defined" do
    it "doesn't attach anything to context/lastCheckout" do
      notice[:context][:lastCheckout] = '123'
      git_last_checkout_filter.call(notice)
      expect(notice[:context][:lastCheckout]).to eq('123')
    end
  end

  context "when .git directory doesn't exist" do
    subject(:git_last_checkout_without_git_dir_filter) { described_class.new('root/dir') }

    it "doesn't attach anything to context/lastCheckout" do
      git_last_checkout_without_git_dir_filter.call(notice)
      expect(notice[:context][:lastCheckout]).to be_nil
    end
  end

  context "when .git directory exists" do
    context "when AIRBRAKE_DEPLOY_USERNAME env variable is set" do
      before { ENV['AIRBRAKE_DEPLOY_USERNAME'] = 'deployer' }

      it "attaches username from the environment" do
        git_last_checkout_filter.call(notice)
        expect(notice[:context][:lastCheckout][:username]).to eq('deployer')
      end
    end

    context "when AIRBRAKE_DEPLOY_USERNAME env variable is NOT set" do
      before { ENV['AIRBRAKE_DEPLOY_USERNAME'] = nil }

      it "attaches last checkouted username" do
        git_last_checkout_filter.call(notice)
        username = notice[:context][:lastCheckout][:username]
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
