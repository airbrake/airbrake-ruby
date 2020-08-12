require_relative 'benchmark_helpers'

Airbrake.configure do |c|
  c.project_id = 1
  c.project_key = '123'
  c.performance_stats = true
  c.performance_stats_flush_period = 0
  c.host = 'http://localhost:8080'
end

query = {
  method: 'GET',
  route: '/things/1',
  query: 'SELECT * FROM foos',
  func: 'foo',
  file: 'foo.rb',
  line: 123,
  timing: 200,
}

request = {
  method: 'GET',
  route: '/things/1',
  status_code: 200,
  timing: 200,
}

breakdown = {
  method: 'GET',
  route: '/things/1',
  response_type: 'json',
  groups: { db: 24.0, view: 0.4 },
  timing: 200,
}

Benchmark.ips do |ips|
  ips.report('Airbrake.notify_query') do
    Airbrake.notify_query(query)
  end

  ips.report('Airbrake.notify_request') do
    Airbrake.notify_request(request)
  end

  ips.report('Airbrake.notify_performance_breakdown') do
    Airbrake.notify_performance_breakdown(breakdown)
  end
end
