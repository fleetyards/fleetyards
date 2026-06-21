# frozen_string_literal: true

Rails.application.configure do
  config.lograge.custom_payload do |controller|
    {
      remote_ip: controller.request.remote_ip,
      user_agent: controller.request.user_agent,
      referer: controller.request.referer
    }
  end
end
