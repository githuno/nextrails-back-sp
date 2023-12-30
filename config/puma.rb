# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Specifies the `worker_timeout` threshold that Puma will use to wait before
# terminating a worker in development environments.
#
worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
#
port ENV.fetch("PORT") { 3000 }

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch("RAILS_ENV") { "development" }

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked web server processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
# workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#

# -----------------------------------------render用に追記 起動コマンドに追加（bundle exec puma -C config/puma.rb;）
# preload_app! # 元々コメントアウトされていた


# before_fork do
#     ActiveRecord::Base.connection_pool.disconnect!
# end

# on_worker_boot do
#     ActiveRecord::Base.establish_connection
# end

# # ワーカープロセスごとのメモリ上限 (MB) の設定
# worker_memory_limit_mb = Integer(ENV['WORKER_MEMORY_LIMIT_MB'] || 512)
# before_fork do |server|
#     server.config[:worker_memory_limit] = worker_memory_limit_mb
# end
# -----------------------------------------render用に追記

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart
