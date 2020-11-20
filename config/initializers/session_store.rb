# frozen_string_literal: true

expire_after = 120.minutes

session_store_options = {
  key: Rails.env.production? ? 'FLTYRD' : "FLTYRD_#{Rails.env.upcase}",
  domain: Rails.application.secrets[:cookie_domain] || :all,
  serializer: :json,
  secure: Rails.env.production? || Rails.env.staging?,
  expire_after: expire_after,
  same_site: :lax,
  redis: {
    expire_after: expire_after,
    ttl: expire_after,
    key_prefix: "fleetyards-#{Rails.env}"
  }
}

Fleetyards::Application.config.session_store :redis_session_store, **session_store_options
