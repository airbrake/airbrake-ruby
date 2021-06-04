RSpec.describe Airbrake::Loggable do
  describe ".instance" do
    it "returns a logger" do
      expect(described_class.instance).to be_a(Logger)
    end
  end

  describe "#logger" do
    subject(:class_with_logger) do
      Class.new { include Airbrake::Loggable }.new
    end

    it "returns a logger that has Logger::WARN severity" do
      expect(class_with_logger.logger.level).to eq(Logger::WARN)
    end
  end
end
