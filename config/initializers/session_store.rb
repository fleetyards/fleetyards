# frozen_string_literal: true

expire_after = 2.hours

session_store_options = {
  servers: "#{ENV['REDIS_URL']}/#{ENV['REDIS_DB'] || 0}/fleetyards-#{Rails.env}-session",
  key: Rails.env.production? ? Rails.application.secrets[:cookie_prefix] : "#{Rails.application.secrets[:cookie_prefix]}_#{Rails.env.upcase}",
  domain: Rails.application.secrets[:cookie_domain] || :all,
  secure: Rails.env.production? || Rails.env.staging?,
  expire_after: expire_after,
  same_site: :lax,
}

Fleetyards::Application.config.session_store :redis_store, **session_store_options
