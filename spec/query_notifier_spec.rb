require 'spec_helper'

RSpec.describe Airbrake::QueryNotifier do
  let(:endpoint) { 'https://api.airbrake.io/api/v5/projects/1/queries-stats' }

  let(:config) do
    Airbrake::Config.new(
      project_id: 1,
      project_key: 'banana',
      performance_stats_flush_period: 0
    )
  end

  subject { described_class.new(config) }

  describe "#notify_query" do
    before do
      stub_request(:put, endpoint).to_return(status: 200, body: '')
    end

    it "rounds time to the floor minute" do
      subject.notify_query(
        query: 'SELECT * FROM foos',
        start_time: Time.new(2018, 1, 1, 0, 0, 20, 0)
      )
      expect(
        a_request(:put, endpoint).with(body: /"time":"2018-01-01T00:00:00\+00:00"/)
      ).to have_been_made
    end

    it "increments routes with the same key" do
      subject.notify_query(
        method: 'GET',
        route: '/foo',
        query: 'SELECT * FROM foos',
        start_time: Time.new(2018, 1, 1, 0, 0, 20, 0)
      )
      subject.notify_query(
        method: 'GET',
        route: '/foo',
        query: 'SELECT * FROM foos',
        start_time: Time.new(2018, 1, 1, 0, 0, 50, 0)
      )
      expect(
        a_request(:put, endpoint).with(body: /"count":2/)
      ).to have_been_made
    end

    it "groups queries by time" do
      subject.notify_query(
        method: 'GET',
        route: '/foo',
        query: 'SELECT * FROM foos',
        start_time: Time.new(2018, 1, 1, 0, 0, 49, 0),
        end_time: Time.new(2018, 1, 1, 0, 0, 50, 0)
      )
      subject.notify_query(
        method: 'GET',
        route: '/foo',
        query: 'SELECT * FROM foos',
        start_time: Time.new(2018, 1, 1, 0, 1, 49, 0),
        end_time: Time.new(2018, 1, 1, 0, 1, 55, 0)
      )
      expect(
        a_request(:put, endpoint).with(
          body: %r|\A
            {"queries":\[
              {"method":"GET","route":"/foo","query":"SELECT\s\*\sFROM\sfoos",
               "time":"2018-01-01T00:00:00\+00:00","count":1,"sum":1000.0,
               "sumsq":1000000.0,"tdigest":"AAAAAkA0AAAAAAAAAAAAAUR6AAAB"},
              {"method":"GET","route":"/foo","query":"SELECT\s\*\sFROM\sfoos",
               "time":"2018-01-01T00:01:00\+00:00","count":1,"sum":6000.0,
               "sumsq":36000000.0,"tdigest":"AAAAAkA0AAAAAAAAAAAAAUW7gAAB"}\]}
          \z|x
        )
      ).to have_been_made
    end

    it "groups queries by route key" do
      subject.notify_query(
        method: 'GET',
        route: '/foo',
        query: 'SELECT * FROM foos',
        start_time: Time.new(2018, 1, 1, 0, 49, 0, 0),
        end_time: Time.new(2018, 1, 1, 0, 50, 0, 0)
      )
      subject.notify_query(
        method: 'POST',
        route: '/foo',
        query: 'SELECT * FROM foos',
        start_time: Time.new(2018, 1, 1, 0, 49, 0, 0),
        end_time: Time.new(2018, 1, 1, 0, 50, 0, 0)
      )
      expect(
        a_request(:put, endpoint).with(
          body: %r|\A
            {"queries":\[
              {"method":"GET","route":"/foo","query":"SELECT\s\*\sFROM\sfoos",
               "time":"2018-01-01T00:49:00\+00:00","count":1,"sum":60000.0,
               "sumsq":3600000000.0,"tdigest":"AAAAAkA0AAAAAAAAAAAAAUdqYAAB"},
              {"method":"POST","route":"/foo","query":"SELECT\s\*\sFROM\sfoos",
               "time":"2018-01-01T00:49:00\+00:00","count":1,"sum":60000.0,
               "sumsq":3600000000.0,"tdigest":"AAAAAkA0AAAAAAAAAAAAAUdqYAAB"}\]}
          \z|x
        )
      ).to have_been_made
    end

    it "returns a promise" do
      promise = subject.notify_query(
        method: 'GET',
        route: '/foo',
        query: 'SELECT * FROM foos',
        start_time: Time.new(2018, 1, 1, 0, 49, 0, 0)
      )
      expect(promise).to be_an(Airbrake::Promise)
      expect(promise.value).to eq('' => nil)
    end
  end
end
