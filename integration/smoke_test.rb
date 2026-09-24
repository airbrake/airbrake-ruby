require 'json'
require 'webrick'

require 'airbrake-ruby'

server = WEBrick::HTTPServer.new(
  BindAddress: '127.0.0.1',
  Port: 0,
  Logger: WEBrick::Log.new(File::NULL),
  AccessLog: [],
)
requests = Queue.new

server.mount_proc('/api/v3/projects/123/notices') do |request, response|
  requests << JSON.parse(request.body)
  response.status = 201
  response['Content-Type'] = 'application/json'
  response.body = { id: 'integration-test' }.to_json
end

thread = Thread.new { server.start }

begin
  begin
    Airbrake.configure do |config|
      config.project_id = 123
      config.project_key = 'integration-test'
      config.error_host = "http://127.0.0.1:#{server.config[:Port]}"
      config.remote_config = false
      config.backlog = false
    end

    raise 'integration exception'
  rescue RuntimeError => error
    response = Airbrake.notify_sync(error)
    unless response['id'] == 'integration-test'
      abort "unexpected response: #{response.inspect}"
    end
  end

  response = Airbrake.notify_sync('integration message')
  unless response['id'] == 'integration-test'
    abort "unexpected response: #{response.inspect}"
  end

  payloads = 2.times.map { requests.pop }
  abort 'exception payload was not sent' unless payloads.any? do |payload|
    payload.dig('errors', 0, 'message') == 'integration exception'
  end
  abort 'message payload was not sent' unless payloads.any? do |payload|
    payload.dig('errors', 0, 'message') == 'integration message'
  end

  puts 'Integration smoke test passed'
ensure
  server.shutdown
  thread.join
end
