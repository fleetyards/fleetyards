# frozen_string_literal: true

api_options = {
  path: (Rails.configuration.app.on_subdomain? ? "" : "api"),
  host: (API_DOMAIN if Rails.configuration.app.on_subdomain? && !Rails.env.test?),
  constraints: ->(req) { !Rails.configuration.app.on_subdomain? || req.subdomain == "api" }
}.compact

namespace :api, **api_options do
  devise_for :users, singular: :user, only: []

  draw 'api/v1/routes'
  draw 'api/v2/routes'

  root to: "base#root"
end
