# frozen_string_literal: true

require File.expand_path('production', __dir__)

Rails.application.configure do
  config.action_cable.allowed_request_origins = ['https://stage.fleetyards.net']
end
