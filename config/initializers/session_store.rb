# frozen_string_literal: true

session_store = :redis_session_store # default :cookie_store
expire_after = 30.minutes

redis_store_options = {
  expire_after: expire_after,
  ttl: expire_after,
  key_prefix: "fleetyards-#{Rails.env}"
}

session_store_options = {
  key: Rails.env.production? ? 'FLTYRD' : "FLTYRD_#{Rails.env.upcase}",
  domain: Rails.application.secrets[:cookie_domain] || :all,
  serializer: :json,
  secure: Rails.env.production?,
  expire_after: expire_after,
  redis: redis_store_options
}

Fleetyards::Application.config.session_store session_store, session_store_options
