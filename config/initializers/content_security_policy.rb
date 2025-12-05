# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

require "uri"

Rails.application.configure do
  config.content_security_policy do |policy|
    api_uri = URI.parse(API_ENDPOINT)
    api_endpoint = "#{api_uri.scheme}://#{api_uri.host}"
    cable_uri = URI.parse(CABLE_ENDPOINT)
    cable_endpoint = "#{cable_uri.scheme}://#{cable_uri.host}"
    admin_uri = URI.parse(ADMIN_ENDPOINT)
    admin_endpoint = "#{admin_uri.scheme}://#{admin_uri.host}"
    cdn_endpoint = Rails.configuration.app.cdn_endpoint
    s3_endpoint = [
      "#{Rails.application.credentials.s3_protocol}://",
      Rails.application.credentials.s3_bucket,
      ".",
      Rails.application.credentials.s3_endpoint
    ].compact.join("")

    connect_src = [
      :self, :data, cable_endpoint, api_endpoint, admin_endpoint, cdn_endpoint,
      "https://img.youtube.com", "https://sentry.io", "https://fonts.googleapis.com",
      "https://fonts.gstatic.com", "https://pro.fontawesome.com", Rails.configuration.rsi.endpoint,
      "https://kit.fontawesome.com", "https://kit-pro.fontawesome.com",
      "https://kit-free.fontawesome.com", "https://ka-p.fontawesome.com", "https://starship42.com",
      s3_endpoint,
      "https://www.gstatic.com",
      "https://cdn.jsdelivr.net",
      "https://stackpath.bootstrapcdn.com"
    ].compact

    connect_src.push("ws://#{ViteRuby.config.host_with_port}") if Rails.env.development?
    connect_src.push("ws://127.0.0.1:3035", "http://127.0.0.1:3035", "ws://127.0.0.1:3136", "http://127.0.0.1:3136") if Rails.env.development?
    connect_src.push("ws://localhost:3035", "http://localhost:3035", "ws://localhost:3136", "http://localhost:3136") if Rails.env.development?
    connect_src.push("ws://fleetyards.test:3035", "http://fleetyards.test:3035", "ws://fleetyards.test:3136", "http://fleetyards.test:3136") if Rails.env.development?
    connect_src.push("ws://api.fleetyards.test:3035", "http://api.fleetyards.test:3035", "ws://api.fleetyards.test:3136", "http://api.fleetyards.test:3136") if Rails.env.development?
    connect_src.push("ws://docs.fleetyards.test:3035", "http://docs.fleetyards.test:3035", "ws://docs.fleetyards.test:3136", "http://docs.fleetyards.test:3136") if Rails.env.development?
    connect_src.push("ws://admin.fleetyards.test:3035", "http://admin.fleetyards.test:3035", "ws://admin.fleetyards.test:3136", "http://admin.fleetyards.test:3136") if Rails.env.development?

    script_src = [
      :self, :unsafe_inline, :unsafe_eval, :blob, cdn_endpoint, "https://www.youtube.com/iframe_api",
      "https://s.ytimg.com", "https://kit.fontawesome.com", "https://kit-pro.fontawesome.com",
      "https://kit-free.fontawesome.com", "https://code.jquery.com", "https://cdn.jsdelivr.net",
      "https://stackpath.bootstrapcdn.com", "https://starship42.com", "https://www.gstatic.com"
    ]
    script_src << "http://#{ViteRuby.config.host_with_port}" if Rails.env.development?

    worker_src = [:self, :blob, FRONTEND_ENDPOINT]

    style_src = [
      :self, :unsafe_inline, cdn_endpoint, "https://fonts.googleapis.com", "https://pro.fontawesome.com",
      "https://kit-pro.fontawesome.com", "https://kit-free.fontawesome.com", "https://ka-p.fontawesome.com"
    ]

    img_src = [
      :self, :data, :blob, FRONTEND_ENDPOINT, api_endpoint, cdn_endpoint,
      Rails.configuration.rsi.endpoint, "https://img.youtube.com", "https://img.buymeacoffee.com",
      "https://validator.swagger.io"
    ].compact

    font_src = [
      :self, :data, cdn_endpoint, "https://fonts.gstatic.com", "https://pro.fontawesome.com",
      "https://kit-pro.fontawesome.com", "https://kit-free.fontawesome.com",
      "https://ka-p.fontawesome.com"
    ]

    frame_src = [
      :self, :blob, FRONTEND_ENDPOINT, "https://youtu.be", "https://www.youtube.com", "https://www.youtube-nocookie.com", "https://starship42.com", "https://starship42.fleetyards.net"
    ]

    form_src = [
      :self, api_endpoint,
      "https://starship42.com",
      FRONTEND_ENDPOINT
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

    policy.upgrade_insecure_requests true unless Rails.env.development? || Rails.env.test?

    # policy.report_uri Rails.application.credentials.sentry_csp_uri if Rails.application.credentials.sentry_csp_uri.present?
  end

  # Generate session nonces for permitted importmap and inline scripts
  # config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  # config.content_security_policy_nonce_directives = %w(script-src)

  # Report violations without enforcing the policy.
  # config.content_security_policy_report_only = true
end
