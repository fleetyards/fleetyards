# frozen_string_literal: true

api_options = {
  path: (Rails.configuration.app.subdomain ? 'api' : ''),
  host: ("api.#{Rails.configuration.app.domain}" if Rails.configuration.app.subdomain && !Rails.env.test?),
  constraints: ->(req) { Rails.configuration.app.subdomain || req.subdomain == 'api' }
}.compact

namespace :api, **api_options do
  devise_for :users, singular: :user, only: []

  draw :api_v1_routes

  root to: 'base#root'
end
