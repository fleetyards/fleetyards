# frozen_string_literal: true

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

require 'uri'

Rails.application.config.content_security_policy do |policy|
  api_endpoint = "https://#{URI.parse(Rails.application.secrets[:api_endpoint]).host}"
  cable_endpoint = "wss://#{URI.parse(Rails.application.secrets[:cable_endpoint]).host}"

  if Rails.env.development?
    api_endpoint = "http://#{URI.parse(Rails.application.secrets[:api_endpoint]).host}"
    cable_endpoint = "ws://#{URI.parse(Rails.application.secrets[:cable_endpoint]).host}"
  end

  connect_src = [
    :self, cable_endpoint, api_endpoint, 'https://img.youtube.com',
    'https://sentry.io', 'https://fonts.googleapis.com', 'https://fonts.gstatic.com',
    'https://pro.fontawesome.com', Rails.application.secrets[:rsi_endpoint],
    'https://kit-pro.fontawesome.com', 'https://kit-free.fontawesome.com'
  ]

  connect_src.concat ['ws://localhost:3035', 'http://localhost:3035'] if Rails.env.development?

  script_src = [
    :self, :unsafe_inline, 'https://www.youtube.com/iframe_api', 'https://s.ytimg.com',
    'https://kit.fontawesome.com', 'https://kit-pro.fontawesome.com',
    'https://kit-free.fontawesome.com'
  ]

  style_src = [
    :self, :unsafe_inline, 'https://fonts.googleapis.com', 'https://pro.fontawesome.com',
    'https://kit-pro.fontawesome.com', 'https://kit-free.fontawesome.com'
  ]

  img_src = [
    :self, :data, :blob, Rails.application.secrets[:frontend_endpoint],
    Rails.application.secrets[:rsi_endpoint], 'https://img.youtube.com',
    'https://fleetyards.s3-eu-west-1.amazonaws.com',
    'https://fleetyards-stage.s3.eu-central-1.amazonaws.com',
    'https://cdn.s3.fleetyards.net'
  ]

  font_src = [
    :self, 'https://fonts.gstatic.com', 'https://pro.fontawesome.com',
    'https://kit-pro.fontawesome.com', 'https://kit-free.fontawesome.com'
  ]

  frame_src = [
    :self, 'https://www.youtube.com', 'https://starship42.com', 'https://starship42.fleetyards.net'
  ]

  policy.default_src :self
  policy.connect_src(*connect_src)
  policy.script_src(*script_src)
  policy.style_src(*style_src)
  policy.img_src(*img_src)
  policy.font_src(*font_src)
  policy.frame_src(*frame_src)
  policy.worker_src :self
  policy.object_src :self
  # policy.report_uri ENV['SENTRY_CSP_URI'] if ENV['SENTRY_CSP_URI'].present?
end
