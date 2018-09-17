# frozen_string_literal: true

workers Integer(ENV['WEB_CONCURRENCY'] || 16)
threads_count = Integer(ENV['MAX_THREADS'] || 128)
threads threads_count, threads_count

pidfile "#{ENV['APP_DIR']}/tmp/pids/puma.pid"
state_path "#{ENV['APP_DIR']}/tmp/pids/puma.state"

prune_bundler

rackup      DefaultRackup
port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'development'
