# frozen_string_literal: true

rails_environment = ENV.fetch('RAILS_ENV') { 'production' }

max_threads_count = ENV.fetch('MAX_THREADS') { 16 }
min_threads_count = ENV.fetch('MIN_THREADS') { rails_environment == 'production' ? max_threads_count : 1 }
threads min_threads_count, max_threads_count

workers Integer(ENV['WORKER_COUNT'] || 2)

port        ENV['PORT'] || 3000

environment rails_environment

# Set up socket location
bind "unix://#{ENV['APP_DIR']}/tmp/pids/puma.sock"

# Set PID and state locations
pidfile "#{ENV['APP_DIR']}/tmp/pids/puma.pid"
state_path "#{ENV['APP_DIR']}/tmp/pids/puma.state"

activate_control_app

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

on_worker_boot do
  require 'active_record'

  # rubocop:disable Style/RescueModifier
  ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished
  # rubocop:enable Style/RescueModifier

  require 'erb'

  ActiveRecord::Base.establish_connection(YAML.safe_load(ERB.new(File.read("#{ENV['APP_DIR']}/config/database.yml")).result)[rails_environment])
end
