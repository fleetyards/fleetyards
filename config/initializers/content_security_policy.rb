# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

require 'uri'

Rails.application.config.content_security_policy do |policy|
  api_uri = URI.parse(API_ENDPOINT)
  api_endpoint = "#{api_uri.scheme}://#{api_uri.host}"
  cable_uri = URI.parse(CABLE_ENDPOINT)
  cable_endpoint = "#{cable_uri.scheme}://#{cable_uri.host}"
  admin_uri = URI.parse(ADMIN_ENDPOINT)
  admin_endpoint = "#{admin_uri.scheme}://#{admin_uri.host}"

  connect_src = [
    :self, :data, cable_endpoint, api_endpoint, admin_endpoint, 'https://img.youtube.com',
    'https://sentry.io', 'https://fonts.googleapis.com', 'https://fonts.gstatic.com',
    'https://pro.fontawesome.com', Rails.configuration.rsi.endpoint,
    'https://kit-pro.fontawesome.com', 'https://kit-free.fontawesome.com',
    'https://ka-p.fontawesome.com', 'https://starship42.com', 'https://www.gstatic.com'
  ]

  connect_src.concat ['ws://localhost:3035', 'http://localhost:3035', "ws://#{ViteRuby.config.host_with_port}"] if Rails.env.development?
  connect_src.concat ['ws://fleetyards.test:3035', 'http://fleetyards.test:3035', 'ws://fleetyards.test:3036'] if Rails.env.development?
  connect_src.concat ['ws://admin.fleetyards.test:3035', 'http://admin.fleetyards.test:3035', 'ws://admin.fleetyards.test:3036'] if Rails.env.development?

  script_src = [
    :self, :unsafe_inline, :unsafe_eval, :blob, 'https://www.youtube.com/iframe_api', 'https://s.ytimg.com',
    'https://kit.fontawesome.com', 'https://kit-pro.fontawesome.com',
    'https://kit-free.fontawesome.com', 'https://code.jquery.com', 'https://cdn.jsdelivr.net',
    'https://stackpath.bootstrapcdn.com', 'https://starship42.com', 'https://www.gstatic.com'
  ]
  script_src << "http://#{ViteRuby.config.host_with_port}" if Rails.env.development?

  worker_src = [:self, :blob, FRONTEND_ENDPOINT]

  style_src = [
    :self, :unsafe_inline, 'https://fonts.googleapis.com', 'https://pro.fontawesome.com',
    'https://kit-pro.fontawesome.com', 'https://kit-free.fontawesome.com', 'https://ka-p.fontawesome.com'
  ]

  img_src = [
    :self, :data, :blob, FRONTEND_ENDPOINT, api_endpoint,
    Rails.application.credentials.carrierwave_cloud_cdn_endpoint, Rails.configuration.rsi.endpoint,
    'https://img.youtube.com', 'https://img.buymeacoffee.com', 'https://validator.swagger.io'
  ].compact

  font_src = [
    :self, 'https://fonts.gstatic.com', 'https://pro.fontawesome.com',
    'https://kit-pro.fontawesome.com', 'https://kit-free.fontawesome.com',
    'https://ka-p.fontawesome.com'
  ]

  frame_src = [
    :self, :blob, FRONTEND_ENDPOINT, 'https://www.youtube.com', 'https://www.youtube-nocookie.com', 'https://starship42.com', 'https://starship42.fleetyards.net'
  ]

  form_src = [
    :self, api_endpoint,
    'https://starship42.com'
  ]

  policy.default_src :none
  policy.base_uri :self
  policy.manifest_src :self
  policy.form_action(*form_src)
  policy.connect_src(*connect_src)
  policy.script_src(*script_src)
  policy.style_src(*style_src)
  policy.img_src(*img_src)
  policy.font_src(*font_src)
  policy.frame_src(*frame_src)
  policy.child_src(*worker_src)
  policy.worker_src(*worker_src)
  policy.prefetch_src(*img_src)
  policy.object_src :self
  policy.frame_ancestors :none
  # policy.report_uri Rails.application.credentials.sentry_csp_uri if Rails.application.credentials.sentry_csp_uri.present?
end
