# frozen_string_literal: true

api_options = {
  path: (Rails.configuration.app.on_subdomain? ? "" : "api"),
  host: (API_DOMAIN if Rails.configuration.app.on_subdomain? && !Rails.env.test?),
  constraints: ->(req) { !Rails.configuration.app.on_subdomain? || req.subdomain == "api" }
}.compact

namespace :api, **api_options do
  draw :api_v1_routes

  root to: "base#root"
end
