# frozen_string_literal: true

Rails.application.configure do
  sanitize = ->(value) { value && value.to_s.delete("\r\n").truncate(512) }

  config.lograge.custom_payload do |controller|
    request = controller.request
    {
      remote_ip: request.remote_ip,
      user_agent: sanitize.call(request.user_agent),
      referer: sanitize.call(request.referer&.split("?", 2)&.first)
    }
  end
end
