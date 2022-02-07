# frozen_string_literal: true

require File.expand_path('production', __dir__)

Rails.application.configure do
  config.log_level = :debug

  config.action_mailer.delivery_method = :postmark
  config.action_mailer.postmark_settings = {
    api_token: Rails.application.credentials.postmark_api_token
  }

  config.action_cable.allowed_request_origins = ['https://stage.fleetyards.net']
end
