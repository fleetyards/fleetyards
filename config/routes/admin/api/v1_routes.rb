# frozen_string_literal: true

v1_admin_api_routes = lambda do
  resource :sessions, only: %i[create destroy]

  resources :admin_users, only: %i[index create update destroy] do
    collection do
      get :me
    end
  end

  resources :users, only: %i[index create update destroy] do
    member do
      get "login-as", to: "users#login_as"
    end
  end

  resources :models, only: %i[index show create update destroy] do
    collection do
      get :options
      get "production-states" => "models#production_states"
    end

    get :images, on: :member
  end

  resources :model_modules, path: "model-modules", only: %i[index]
  resources :model_paints, path: "model-paints", only: %i[index]

  resources :manufacturers, only: %i[index show]

  resources :components, only: %i[index show] do
    get :class_filters, on: :collection
    get :item_type_filters, on: :collection
  end

  resources :vehicles, only: %i[index]

  resources :item_prices, path: "item-prices", only: %i[index show create update destroy]

  resource :stats, only: [] do
    get "quick-stats" => "stats#quick_stats"
    get "most-viewed-pages" => "stats#most_viewed_pages"
    get "visits-per-day" => "stats#visits_per_day"
    get "visits-per-month" => "stats#visits_per_month"
    get "registrations-per-month" => "stats#registrations_per_month"
  end

  resources :images, only: %i[index create destroy update]

  resources :imports, only: %i[index show]
end

scope :v1, as: :v1 do
  scope module: :v1, &v1_admin_api_routes
end
