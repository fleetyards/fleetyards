# frozen_string_literal: true

docs_options = {
  path: (Rails.configuration.app.on_subdomain? ? "" : "docs"),
  host: (DOCS_DOMAIN if Rails.configuration.app.on_subdomain? && !Rails.env.test?),
  constraints: ->(req) { !Rails.configuration.app.on_subdomain? || req.subdomain == "docs" }
}.compact

namespace :docs, **docs_options do
  root to: "/docs#index"
end

Rails.application.routes.append do
  namespace :docs, **docs_options do
    match "*path", to: "/docs#index", via: :all
  end
end
