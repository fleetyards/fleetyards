# frozen_string_literal: true

namespace :api, path: (ENV['ON_SUBDOMAIN'] ? 'api' : ''), constraints: ->(req) { ENV['ON_SUBDOMAIN'] || req.subdomain == 'api' } do
  devise_for :users, singular: :user, only: []

  draw :api_v1_routes

  root to: 'base#root'
end
