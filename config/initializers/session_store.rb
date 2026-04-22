# frozen_string_literal: true

expire_after = 2.hours

# ERB in YAML converts the :all symbol to the string "all" — convert it back
# so ActionDispatch applies its "use the request host" logic.
cookie_domain = Rails.configuration.app.cookie_domain
cookie_domain = :all if cookie_domain.to_s == "all"

session_store_options = {
  servers: "#{Rails.configuration.redis.url}/#{Rails.configuration.redis.db}/fleetyards-#{Rails.env}-session",
  key: Rails.configuration.cookie_prefix,
  domain: cookie_domain,
  secure: Rails.env.production? || Rails.env.staging?,
  expire_after:,
  same_site: :lax
}

Rails.application.config.session_store :redis_store, **session_store_options
