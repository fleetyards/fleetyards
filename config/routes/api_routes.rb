# frozen_string_literal: true

api_options = {
  path: (Rails.configuration.app.on_subdomain? ? "" : "api"),
  host: (API_DOMAIN if Rails.configuration.app.on_subdomain? && !Rails.env.test?),
  constraints: ->(req) { !Rails.configuration.app.on_subdomain? || req.subdomain == "api" }
}.compact

namespace :api, **api_options do
  devise_for :users, singular: :user, only: []

  draw "api/v1_routes"

  get "docs", to: redirect(DOCS_ENDPOINT, allow_other_host: true)

  scope format: true, constraints: {format: "yaml"} do
    get ":api_version/schema" => "schema#index", :as => :schema
  end

  root to: "base#root"
end
