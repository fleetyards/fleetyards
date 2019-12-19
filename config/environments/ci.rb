# frozen_string_literal: true

require 'uglifier'
require File.expand_path('production', __dir__)

Rails.application.configure do
  config.force_ssl = false

  config.action_mailer.delivery_method = :test

  config.action_cable.allowed_request_origins = ['http://fleetyards.test', 'http://www.fleetyards.test', 'http://localhost:8270']
end
