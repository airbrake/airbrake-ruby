require 'spec_helper'

RSpec.describe Airbrake::RouteSender do
  let(:endpoint) { 'https://api.airbrake.io/api/v5/projects/1/routes-stats' }

  let(:config) do
    Airbrake::Config.new(
      project_id: 1,
      project_key: 'banana',
      route_stats_flush_period: 0.1
    )
  end

  subject { described_class.new(config) }

  describe "#inc_request" do
    before do
      stub_request(:put, endpoint).to_return(status: 200, body: '')
    end

    # Let the request finish.
    after { sleep 0.2 }

    it "rounds time to the floor minute" do
      subject.inc_request('GET', '/foo', 200, 24, Time.new(2018, 1, 1, 0, 0, 20, 0))
      sleep 0.2
      expect(
        a_request(:put, endpoint).with(body: /"time":"2018-01-01T00:00:00\+00:00"/)
      ).to have_been_made
    end

    it "increments routes with the same key" do
      subject.inc_request('GET', '/foo', 200, 24, Time.new(2018, 1, 1, 0, 0, 20, 0))
      subject.inc_request('GET', '/foo', 200, 24, Time.new(2018, 1, 1, 0, 0, 50, 0))
      sleep 0.2
      expect(
        a_request(:put, endpoint).with(body: /"count":2/)
      ).to have_been_made
    end

    it "groups routes by time" do
      subject.inc_request('GET', '/foo', 200, 24, Time.new(2018, 1, 1, 0, 0, 20, 0))
      subject.inc_request('GET', '/foo', 200, 10, Time.new(2018, 1, 1, 0, 1, 20, 0))
      sleep 0.2
      expect(
        a_request(:put, endpoint).with(
          body: %r|\A
            {"routes":\[
              {"method":"GET","route":"/foo","status_code":200,
               "time":"2018-01-01T00:00:00\+00:00","count":1,"sum":24.0,
               "sumsq":576.0,"tdigest":"AAAAAkA0AAAAAAAAAAAAAUHAAAAB"},
              {"method":"GET","route":"/foo","status_code":200,
               "time":"2018-01-01T00:01:00\+00:00","count":1,"sum":10.0,
               "sumsq":100.0,"tdigest":"AAAAAkA0AAAAAAAAAAAAAUEgAAAB"}\]}
          \z|x
        )
      ).to have_been_made
    end

    it "groups routes by route key" do
      subject.inc_request('GET', '/foo', 200, 24, Time.new(2018, 1, 1, 0, 0, 20, 0))
      subject.inc_request('POST', '/foo', 200, 10, Time.new(2018, 1, 1, 0, 0, 20, 0))
      sleep 0.2
      expect(
        a_request(:put, endpoint).with(
          body: %r|\A
            {"routes":\[
              {"method":"GET","route":"/foo","status_code":200,
               "time":"2018-01-01T00:00:00\+00:00","count":1,"sum":24.0,
               "sumsq":576.0,"tdigest":"AAAAAkA0AAAAAAAAAAAAAUHAAAAB"},
              {"method":"POST","route":"/foo","status_code":200,
               "time":"2018-01-01T00:00:00\+00:00","count":1,"sum":10.0,
               "sumsq":100.0,"tdigest":"AAAAAkA0AAAAAAAAAAAAAUEgAAAB"}\]}
          \z|x
        )
      ).to have_been_made
    end

    it "returns a promise" do
      promise = subject.inc_request('GET', '/foo', 200, 24, Time.new)
      sleep 0.2
      expect(promise).to be_an(Airbrake::Promise)
      expect(promise.value).to eq('' => nil)
    end
  end
end
