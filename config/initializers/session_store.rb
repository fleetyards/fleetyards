# frozen_string_literal: true

session_store_options = {
  key: Rails.env.production? ? 'FLTYRD' : "FLTYRD_#{Rails.env.upcase}",
  domain: Rails.application.secrets[:cookie_domain] || :all,
  serializer: :json,
  secure: Rails.env.production? || Rails.env.staging?,
  expire_after: 120.minutes,
  same_site: :lax
}

Fleetyards::Application.config.session_store :cookie_store, **session_store_options
