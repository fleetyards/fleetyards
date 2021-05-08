# frozen_string_literal: true

namespace :api, path: (Rails.configuration.x.app.subdomain ? 'api' : ''), constraints: ->(req) { Rails.configuration.x.app.subdomain || req.subdomain == 'api' } do
  devise_for :users, singular: :user, only: []

  draw :api_v1_routes

  root to: 'base#root'
end
