require 'spec_helper'

RSpec.describe Airbrake::Filters::ThreadFilter do
  subject { described_class.new }

  let(:notice) { Airbrake::Notice.new(Airbrake::Config.new, AirbrakeTestError.new) }
  let(:th) { Thread.current }

  it "appends thread variables" do
    th.thread_variable_set(:bingo, :bango)
    subject.call(notice)
    th.thread_variable_set(:bingo, nil)

    expect(notice[:params][:thread][:thread_variables][:bingo]).to eq(:bango)
  end

  it "appends fiber variables" do
    th[:bingo] = :bango
    subject.call(notice)
    th[:bingo] = nil

    expect(notice[:params][:thread][:fiber_variables][:bingo]).to eq(:bango)
  end

  it "appends name", skip: !Thread.current.respond_to?(:name) do
    th.name = 'bingo'
    subject.call(notice)
    th.name = nil

    expect(notice[:params][:thread][:name]).to eq('bingo')
  end

  it "appends thread inspect (self)" do
    subject.call(notice)
    expect(notice[:params][:thread][:self]).to match(/\A#<Thread:.+ run>\z/)
  end

  it "appends thread group" do
    subject.call(notice)
    expect(notice[:params][:thread][:group][0]).to match(/\A#<Thread:.+ run>\z/)
  end

  it "appends priority" do
    subject.call(notice)
    expect(notice[:params][:thread][:priority]).to eq(0)
  end

  it "appends safe_level", skip: Airbrake::JRUBY do
    subject.call(notice)
    expect(notice[:params][:thread][:safe_level]).to eq(0)
  end

  context "when an IO-like object is stored" do
    let(:io_obj) do
      Class.new(IO) do
        def initialize; end
      end.new
    end

    before do
      expect(io_obj).to be_is_a(IO)
    end

    it "doesn't append the IO object to thread variables" do
      th.thread_variable_set(:io, io_obj)
      subject.call(notice)
      th.thread_variable_set(:io, nil)

      expect(notice[:params][:thread][:thread_variables][:io]).to be_nil
    end

    it "doesn't append the IO object to thread variables" do
      th[:io] = io_obj
      subject.call(notice)
      th[:io] = nil

      expect(notice[:params][:thread][:fiber_variables][:io]).to be_nil
    end
  end
end
