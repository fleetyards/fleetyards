# frozen_string_literal: true

v1_api_routes = lambda do
  get "version", to: "base#version"
  get "sc-data/version", to: "sc_data#current_version"

  resource :features, only: %i[show]

  resource :sessions, only: %i[create destroy] do
    post "confirm-access", to: "sessions#confirm_access", on: :collection
  end

  resource :password, only: [:update] do
    collection do
      post "request", to: "passwords#request_email"
      put "update", to: "passwords#update"
      put "update/:reset_password_token", to: "passwords#update_with_token"
    end
  end

  draw "api/users_routes"
  draw "api/models_routes"
  draw "api/hangar_routes"
  draw "api/vehicles_routes"
  draw "api/fleets_routes"
  draw "api/stations_routes"
  draw "api/shop_commodities_routes"

  resources :manufacturers, param: :slug, only: %i[index] do
    get "with-models", to: "manufacturers#with_models", on: :collection
  end

  resources :images, only: %i[index] do
    get :random, on: :collection
  end

  resources :roadmap, only: %i[index] do
    get :weeks, on: :collection
  end

  resources :search, only: %i[index]

  resources :trade_routes, path: "trade-routes", only: [:index]

  resources :commodities, only: [:index] do
    get "types", to: "commodities#commodity_types", on: :collection
  end

  resources :equipment, only: [:index]

  resources :components, only: [:index] do
    get :class_filters, on: :collection
    get :item_type_filters, on: :collection
  end

  resources :starsystems, param: :slug, only: %i[index show]

  resources :celestial_objects, path: "celestial-objects", param: :slug, only: %i[index show]

  resources :commodity_prices, path: "commodity-prices", only: [:create] do
    get "time-ranges", to: "commodity_prices#time_ranges", on: :collection
  end

  namespace :stats do
    get "quick-stats", to: "base#quick_stats"
    get "models-per-month", to: "base#models_per_month"
    get "models-by-size", to: "base#models_by_size"
    get "models-by-production-status", to: "base#models_by_production_status"
    get "models-by-manufacturer", to: "base#models_by_manufacturer"
    get "models-by-classification", to: "base#models_by_classification"
    get "components-by-class", to: "base#components_by_class"
  end
end

scope :v1, as: :v1 do
  scope module: :v1, &v1_api_routes

  root to: "v1/base#root"
end
