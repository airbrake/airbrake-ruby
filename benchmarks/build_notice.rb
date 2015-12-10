require_relative 'benchmark_helpers'

Airbrake.configure do |c|
  c.project_id = 1
  c.project_key = '213'
  c.logger = Logger.new('/dev/null')
end

puts "Calculating iterations/second..."

Benchmark.ips do |ips|
  ips.config(time: 5, warmup: 5)

  ips.report("big   Airbrake.build_notice") do
    Airbrake.build_notice(BIG_EXCEPTION)
  end

  ips.report("small Airbrake.build_notice") do
    Airbrake.build_notice(SMALL_EXCEPTION)
  end

  ips.compare!
end

NOTICES = 100_000

puts "Calculating times..."

Benchmark.bmbm do |bm|
  bm.report("big   Airbrake.build_notice") do
    NOTICES.times { Airbrake.build_notice(BIG_EXCEPTION) }
  end

  bm.report("small Airbrake.build_notice") do
    NOTICES.times { Airbrake.build_notice(SMALL_EXCEPTION) }
  end
end
