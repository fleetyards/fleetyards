# frozen_string_literal: true

require File.expand_path('production', __dir__)

Rails.application.configure do
  config.log_level = :debug

  config.hosts = [/fleetyards-pr-[0-9]*.herokuapp.com/]

  config.action_cable.allowed_request_origins = [%r{https://fleetyards-pr-*.herokuapp.com}]
end
