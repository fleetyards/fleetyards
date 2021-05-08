# frozen_string_literal: true

expire_after = 2.hours

session_store_options = {
  servers: "#{Rails.configuration.x.redis.url}/#{Rails.configuration.x.redis.db}/fleetyards-#{Rails.env}-session",
  key: Rails.configuration.cookie_prefix,
  domain: Rails.configuration.x.app.cookie_domain,
  secure: Rails.env.production? || Rails.env.staging?,
  expire_after: expire_after,
  same_site: :lax,
}

Fleetyards::Application.config.session_store :redis_store, **session_store_options
