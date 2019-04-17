# frozen_string_literal: true

workers Integer(ENV['WEB_CONCURRENCY'] || 2)

threads_count = Integer(ENV['MAX_THREADS'] || 16)
threads 1, threads_count

port        ENV['PORT']      || 3000
# Default to production
rails_env = ENV['RAILS_ENV'] || 'production'
environment rails_env

# Set up socket location
bind "unix://#{ENV['APP_DIR']}/tmp/pids/puma.sock"

# Set master PID and state locations
pidfile "#{ENV['APP_DIR']}/tmp/pids/puma.pid"
state_path "#{ENV['APP_DIR']}/tmp/pids/puma.state"
activate_control_app

on_worker_boot do
  require 'active_record'

  # rubocop:disable Style/RescueModifier
  ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished
  # rubocop:enable Style/RescueModifier

  require 'erb'

  ActiveRecord::Base.establish_connection(YAML.safe_load(ERB.new(File.read("#{ENV['APP_DIR']}/config/database.yml")).result)[rails_env])
end
