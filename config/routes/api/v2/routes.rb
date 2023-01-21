# frozen_string_literal: true

v2_api_routes = lambda do
  resources :components, only: [:index]

  resources :equipment, only: [:index]

  draw "api/v2/filters"

  draw "api/v2/fleets"

  draw "api/v2/hangar"

  resources :images, only: %i[index]

  resources :manufacturers, param: :slug, only: %i[index]

  draw "api/v2/models"

  resources :roadmap, only: %i[index] do
    get :weeks, on: :collection
  end

  resource :sc_data, path: "sc-data", only: [] do
    get :current_version, path: "version"
  end

  resources :search, only: %i[index]

  resource :sessions, only: %i[create destroy] do
    collection do
      post "confirm-access" => "sessions#confirm_access"
    end
  end

  draw "api/v2/stations"

  draw "api/v2/stats"

  resources :trade_routes, path: "trade-routes", only: [:index]

  draw "api/v2/users"

  get "version" => "base#version"
end

scope :v2, as: :v2 do
  scope module: :v2, &v2_api_routes

  root to: "v2/base#root"
end
