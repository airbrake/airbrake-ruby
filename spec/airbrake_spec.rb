RSpec.describe Airbrake do
  before do
    Airbrake::Config.instance = Airbrake::Config.new
    described_class.reset
  end

  after { described_class.reset }

  describe ".configure" do
    it "yields the config" do
      expect do |b|
        begin
          described_class.configure(&b)
        rescue Airbrake::Error
          nil
        end
      end.to yield_with_args(Airbrake::Config)
    end

    it "sets logger to Airbrake::Loggable" do
      logger = Logger.new(File::NULL)
      described_class.configure do |c|
        c.project_id = 1
        c.project_key = '123'
        c.logger = logger
      end

      expect(Airbrake::Loggable.instance).to eql(logger)
    end

    it "makes Airbrake configured" do
      expect(described_class).not_to be_configured

      described_class.configure do |c|
        c.project_id = 1
        c.project_key = '2'
      end

      expect(described_class).to be_configured
    end

    context "when a notifier was configured" do
      before do
        expect(described_class).to receive(:configured?).twice.and_return(true)
      end

      it "closes previously configured notice notifier" do
        expect(described_class).to receive(:close).twice
        described_class.configure {}
      end
    end

    context "when a notifier wasn't configured" do
      before do
        expect(described_class).to receive(:configured?).twice.and_return(false)
      end

      it "doesn't close previously configured notice notifier" do
        expect(described_class).not_to receive(:close)
        described_class.configure {}
      end
    end
  end

  describe "#reset" do
    context "when Airbrake was previously configured" do
      before do
        expect(described_class).to receive(:configured?).twice.and_return(true)
      end

      it "closes notice notifier" do
        expect(described_class).to receive(:close).twice
        subject.reset
      end
    end
  end
end
