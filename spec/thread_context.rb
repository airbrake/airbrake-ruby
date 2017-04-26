require 'spec_helper'

RSpec.describe Airbrake::ThreadContext do
  subject! { described_class.new('test') }

  describe "#[]=" do
    it "sets a thread context value" do
      subject[:bingo] = :bango
      expect(subject[:bingo]).to eq(:bango)
    end

    it "uses the correct name for the thread variable" do
      expect(
        Thread.current.thread_variable_get('airbrake_ruby_context_test')
      ).to be_a(Hash)

      expect(
        Thread.current.thread_variable_get('airbrake_ruby_context_test2')
      ).to be_nil

      described_class.new('test2')

      expect(
        Thread.current.thread_variable_get('airbrake_ruby_context_test2')
      ).to be_a(Hash)
    end
  end

  describe "#clear" do
    it "clears the thread context" do
      subject[:bingo] = :bongo
      subject.clear
      expect(subject[:bingo]).to be_nil
    end
  end

  describe "#to_h" do
    it "converts the thread context to a hash" do
      subject[:bingo] = :bango
      subject[:bongo] = [:bish]
      subject[:bash] = { bosh: :foo }

      expect(subject.to_h).to(
        eq(
          bingo: :bango,
          bongo: [:bish],
          bash: { bosh: :foo }
        )
      )
    end
  end
end
