RSpec.describe Airbrake do
  before { Airbrake::Config.instance = Airbrake::Config.new }

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
  end
end
