# encoding: utf-8
# frozen_string_literal: true
workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads_count = Integer(ENV['MAX_THREADS'] || 5)
threads threads_count, threads_count

directory ENV['APP_DIR']

rackup DefaultRackup
port ENV['PORT'] || 3000
environment ENV['RACK_ENV'] || 'development'

activate_control_app "tcp://127.0.0.1:#{ENV['CTRL_PORT'].to_i}", no_token: true

daemonize true
pidfile "#{ENV['SHARED_DIR']}/tmp/pids/puma.pid"
state_path "#{ENV['SHARED_DIR']}/tmp/pids/puma.state"
