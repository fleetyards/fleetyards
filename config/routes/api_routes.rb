# frozen_string_literal: true

namespace :api, path: (Rails.configuration.app.subdomain ? 'api' : ''), constraints: ->(req) { Rails.configuration.app.subdomain || req.subdomain == 'api' } do
  devise_for :users, singular: :user, only: []

  draw :api_v1_routes

  root to: 'base#root'
end
