# frozen_string_literal: true

rails_environment = ENV.fetch("RAILS_ENV", "development")
app_dir = ENV.fetch("APP_DIR", ".")

max_threads_count = Integer(ENV.fetch("MAX_THREADS", 2))
min_threads_count = Integer(ENV.fetch("MIN_THREADS") { max_threads_count } || 1)
threads min_threads_count, max_threads_count

workers Integer(ENV.fetch("WORKER_COUNT", 2))

port ENV.fetch("PORT", 3000)

environment rails_environment

# Set up socket location
bind "unix://#{app_dir}/tmp/pids/puma.sock"

# Set PID and state locations
pidfile "#{app_dir}/tmp/pids/puma.pid"
state_path "#{app_dir}/tmp/pids/puma.state"

activate_control_app

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

on_worker_boot do
  require "active_record"

  # rubocop:disable Style/RescueModifier
  ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished
  # rubocop:enable Style/RescueModifier

  require "erb"

  ActiveRecord::Base.establish_connection(YAML.safe_load(ERB.new(File.read("#{app_dir}/config/database.yml")).result)[rails_environment])
end
