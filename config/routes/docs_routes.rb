# frozen_string_literal: true

docs_options = {
  path: (Rails.configuration.app.on_subdomain? ? "" : "docs"),
  host: (DOCS_DOMAIN if Rails.configuration.app.on_subdomain? && !Rails.env.test?),
  constraints: ->(req) { !Rails.configuration.app.on_subdomain? || req.subdomain == "docs" }
}.compact

namespace :docs, **docs_options do
  scope :api do
    get :v1, to: "/docs#index"
    get "/", to: "/docs#index"
  end
  get :embed, to: "/docs#index"

  root to: "/docs#index"
end
