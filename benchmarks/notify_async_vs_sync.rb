require_relative 'benchmark_helpers'

# Silence logs.
logger = Logger.new('/dev/null')

# Setup Airbrake.
Airbrake.configure do |c|
  c.project_id = 112261
  c.project_key = 'c7aaceb2ccb579e6b710cea9da22c526'
  c.logger = logger
  c.host = 'http://localhost:8080'
end

# The number of notices to process.
NOTICES = 1200

# Don't forget to run the server: go run benchmarks/server.go
Benchmark.bm do |bm|
  bm.report("Airbrake.notify") do
    NOTICES.times { Airbrake.notify(BIG_EXCEPTION) }
  end

  bm.report("Airbrake.notify_sync") do
    NOTICES.times { Airbrake.notify_sync(BIG_EXCEPTION) }
  end
end
