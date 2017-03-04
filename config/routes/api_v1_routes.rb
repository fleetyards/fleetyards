# encoding: utf-8
# frozen_string_literal: true
v1_api_routes = lambda do
  resources :ships, only: [:index, :show]
end

scope :v1, defaults: { format: :json }, as: :v1 do
  scope module: :v1, &v1_api_routes
end
