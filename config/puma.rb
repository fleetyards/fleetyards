# encoding: utf-8
# frozen_string_literal: true
workers Integer(ENV['WEB_CONCURRENCY'] || 3)
threads_count = Integer(ENV['MAX_THREADS'] || 16)
threads 0, threads_count

directory ENV['APP_DIR']
pidfile "#{ENV['SHARED_DIR']}/tmp/pids/puma.pid"
state_path "#{ENV['SHARED_DIR']}/tmp/sockets/puma.state"

prune_bundler

rackup DefaultRackup
port ENV['PORT'] || 3000
environment ENV['RACK_ENV'] || 'development'
