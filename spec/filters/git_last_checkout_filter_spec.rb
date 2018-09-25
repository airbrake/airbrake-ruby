require 'spec_helper'

RSpec.describe Airbrake::Filters::GitLastCheckoutFilter do
  subject { described_class.new(Logger.new(STDOUT), '.') }

  let(:notice) do
    Airbrake::Notice.new(Airbrake::Config.new, AirbrakeTestError.new)
  end

  context "when context/lastCheckout is defined" do
    it "doesn't attach anything to context/lastCheckout" do
      notice[:context][:lastCheckout] = '123'
      subject.call(notice)
      expect(notice[:context][:lastCheckout]).to eq('123')
    end
  end

  context "when .git directory doesn't exist" do
    subject { described_class.new(Logger.new(STDOUT), 'root/dir') }

    it "doesn't attach anything to context/lastCheckout" do
      subject.call(notice)
      expect(notice[:context][:lastCheckout]).to be_nil
    end
  end

  context "when .git directory exists" do
    before { subject.call(notice) }

    it "attaches last checkouted username" do
      expect(notice[:context][:lastCheckout][:username]).not_to be_empty
    end

    it "attaches last checkouted email" do
      expect(notice[:context][:lastCheckout][:email]).to match(/\A\w+@\w+\.?\w+?\z/)
    end

    it "attaches last checkouted revision" do
      expect(notice[:context][:lastCheckout][:revision]).not_to be_empty
      expect(notice[:context][:lastCheckout][:revision].size).to eq(40)
    end

    it "attaches last checkouted time" do
      expect(notice[:context][:lastCheckout][:time]).not_to be_empty
      expect(notice[:context][:lastCheckout][:time].size).to eq(25)
    end
  end
end
