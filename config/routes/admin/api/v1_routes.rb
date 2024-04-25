# frozen_string_literal: true

v1_admin_api_routes = lambda do
  resources :models, only: %i[index] do
    collection do
      get :options
      get "production-states" => "models#production_states"
    end

    get :images, on: :member
  end

  resources :model_modules, path: "model-modules", only: [:index]
  resources :model_paints, path: "model-paints", only: [:index]

  resources :manufacturers, only: %i[index]

  resources :components, only: [:index] do
    get :class_filters, on: :collection
    get :item_type_filters, on: :collection
  end

  resources :item_prices, path: "item-prices", only: %i[index show create update destroy]

  resource :stats, only: [] do
    get "quick-stats" => "stats#quick_stats"
    get "most-viewed-pages" => "stats#most_viewed_pages"
    get "visits-per-day" => "stats#visits_per_day"
    get "visits-per-month" => "stats#visits_per_month"
    get "registrations-per-month" => "stats#registrations_per_month"
  end

  resources :images, only: %i[index create destroy update]
end

scope :v1, as: :v1 do
  scope module: :v1, &v1_admin_api_routes
end
