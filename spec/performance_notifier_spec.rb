require 'spec_helper'

RSpec.describe Airbrake::PerformanceNotifier do
  let(:routes) { 'https://api.airbrake.io/api/v5/projects/1/routes-stats' }
  let(:queries) { 'https://api.airbrake.io/api/v5/projects/1/queries-stats' }

  let(:config) do
    Airbrake::Config.new(
      project_id: 1,
      project_key: 'banana',
      performance_stats: true,
      performance_stats_flush_period: 0
    )
  end

  subject { described_class.new(config) }

  describe "#notify" do
    before do
      stub_request(:put, routes).to_return(status: 200, body: '')
      stub_request(:put, queries).to_return(status: 200, body: '')
    end

    it "rounds time to the floor minute" do
      subject.notify(
        Airbrake::Request.new(
          method: 'GET',
          route: '/foo',
          status_code: 200,
          start_time: Time.new(2018, 1, 1, 0, 0, 20, 0)
        )
      )
      expect(
        a_request(:put, routes).with(body: /"time":"2018-01-01T00:00:00\+00:00"/)
      ).to have_been_made
    end

    it "increments routes with the same key" do
      subject.notify(
        Airbrake::Request.new(
          method: 'GET',
          route: '/foo',
          status_code: 200,
          start_time: Time.new(2018, 1, 1, 0, 0, 20, 0)
        )
      )
      subject.notify(
        Airbrake::Request.new(
          method: 'GET',
          route: '/foo',
          status_code: 200,
          start_time: Time.new(2018, 1, 1, 0, 0, 50, 0)
        )
      )
      expect(
        a_request(:put, routes).with(body: /"count":2/)
      ).to have_been_made
    end

    it "groups routes by time" do
      subject.notify(
        Airbrake::Request.new(
          method: 'GET',
          route: '/foo',
          status_code: 200,
          start_time: Time.new(2018, 1, 1, 0, 0, 49, 0),
          end_time: Time.new(2018, 1, 1, 0, 0, 50, 0)
        )
      )
      subject.notify(
        Airbrake::Request.new(
          method: 'GET',
          route: '/foo',
          status_code: 200,
          start_time: Time.new(2018, 1, 1, 0, 1, 49, 0),
          end_time: Time.new(2018, 1, 1, 0, 1, 55, 0)
        )
      )
      expect(
        a_request(:put, routes).with(
          body: %r|\A
            {"routes":\[
              {"method":"GET","route":"/foo","statusCode":200,
               "time":"2018-01-01T00:00:00\+00:00","count":1,"sum":1000.0,
               "sumsq":1000000.0,"tdigest":"AAAAAkA0AAAAAAAAAAAAAUR6AAAB"},
              {"method":"GET","route":"/foo","statusCode":200,
               "time":"2018-01-01T00:01:00\+00:00","count":1,"sum":6000.0,
               "sumsq":36000000.0,"tdigest":"AAAAAkA0AAAAAAAAAAAAAUW7gAAB"}\]}
          \z|x
        )
      ).to have_been_made
    end

    it "groups routes by route key" do
      subject.notify(
        Airbrake::Request.new(
          method: 'GET',
          route: '/foo',
          status_code: 200,
          start_time: Time.new(2018, 1, 1, 0, 49, 0, 0),
          end_time: Time.new(2018, 1, 1, 0, 50, 0, 0)
        )
      )
      subject.notify(
        Airbrake::Request.new(
          method: 'POST',
          route: '/foo',
          status_code: 200,
          start_time: Time.new(2018, 1, 1, 0, 49, 0, 0),
          end_time: Time.new(2018, 1, 1, 0, 50, 0, 0)
        )
      )
      expect(
        a_request(:put, routes).with(
          body: %r|\A
            {"routes":\[
              {"method":"GET","route":"/foo","statusCode":200,
               "time":"2018-01-01T00:49:00\+00:00","count":1,"sum":60000.0,
               "sumsq":3600000000.0,"tdigest":"AAAAAkA0AAAAAAAAAAAAAUdqYAAB"},
              {"method":"POST","route":"/foo","statusCode":200,
               "time":"2018-01-01T00:49:00\+00:00","count":1,"sum":60000.0,
               "sumsq":3600000000.0,"tdigest":"AAAAAkA0AAAAAAAAAAAAAUdqYAAB"}\]}
          \z|x
        )
      ).to have_been_made
    end

    it "returns a promise" do
      promise = subject.notify(
        Airbrake::Request.new(
          method: 'GET',
          route: '/foo',
          status_code: 200,
          start_time: Time.new(2018, 1, 1, 0, 49, 0, 0)
        )
      )
      expect(promise).to be_an(Airbrake::Promise)
      expect(promise.value).to eq('' => nil)
    end

    it "doesn't send route stats when performance stats are disabled" do
      notifier = described_class.new(
        Airbrake::Config.new(
          project_id: 1, project_key: '2', performance_stats: false
        )
      )
      promise = notifier.notify(
        Airbrake::Request.new(
          method: 'GET', route: '/foo', status_code: 200, start_time: Time.new
        )
      )
      expect(a_request(:put, routes)).not_to have_been_made
      expect(promise.value).to eq(
        'error' => "The Performance Stats feature is disabled"
      )
    end

    it "doesn't send route stats when current environment is ignored" do
      notifier = described_class.new(
        Airbrake::Config.new(
          project_id: 1, project_key: '2', performance_stats: true,
          environment: 'test', ignore_environments: %w[test]
        )
      )
      promise = notifier.notify(
        Airbrake::Request.new(
          method: 'GET', route: '/foo', status_code: 200, start_time: Time.new
        )
      )
      expect(a_request(:put, routes)).not_to have_been_made
      expect(promise.value).to eq('error' => "The 'test' environment is ignored")
    end

    describe "payload grouping" do
      let(:flush_period) { 0.5 }

      let(:config) do
        Airbrake::Config.new(
          project_id: 1,
          project_key: 'banana',
          performance_stats: true,
          performance_stats_flush_period: flush_period
        )
      end

      it "groups payload by performance name and sends it separately" do
        subject.notify(
          Airbrake::Request.new(
            method: 'GET',
            route: '/foo',
            status_code: 200,
            start_time: Time.new(2018, 1, 1, 0, 49, 0, 0)
          )
        )

        subject.notify(
          Airbrake::Query.new(
            method: 'POST',
            route: '/foo',
            query: 'SELECT * FROM things',
            start_time: Time.new(2018, 1, 1, 0, 49, 0, 0)
          )
        )

        sleep(flush_period + 0.5)

        expect(a_request(:put, routes)).to have_been_made
        expect(a_request(:put, queries)).to have_been_made
      end
    end
  end
end
