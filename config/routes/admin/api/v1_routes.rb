# frozen_string_literal: true

v1_admin_api_routes = lambda do
  resource :sessions, only: %i[create destroy]

  resources :admin_users, only: %i[index show create update destroy] do
    collection do
      get :me
    end
  end

  resources :users, only: %i[index show update destroy] do
    member do
      get "login-as", to: "users#login_as"
      post "resend-confirmation", to: "users#resend_confirmation"
      post "send-password-reset", to: "users#send_password_reset"
    end
  end

  resources :models, only: %i[index show create update destroy] do
    collection do
      get :options
      get "production-states" => "models#production_states"
      put "reload-matrix" => "models#reload_matrix"
      put "reload-scdata" => "models#reload_scdata"
      put "reload-loaners" => "models#reload_loaners"
      put "reload-paints" => "models#reload_paints"
    end

    member do
      put "use-rsi-image" => "models#use_rsi_image"
      put "reload-one" => "models#reload_one"
    end
  end

  resources :videos, only: %i[index show create update destroy]
  resources :model_modules, path: "model-modules", only: %i[index show create update destroy] do
    member do
      put :link
      put :unlink
    end
  end
  resources :model_paints, path: "model-paints", only: %i[index show create update destroy]
  resources :model_upgrades, path: "model-upgrades", only: %i[index show create update destroy] do
    member do
      put :link
      put :unlink
    end
  end
  resources :model_module_packages, path: "model-module-packages", only: %i[index show create update destroy]
  resources :docks, only: %i[index show create update destroy]
  resources :model_hardpoints, path: "model-hardpoints", only: %i[index show create update destroy]
  resources :model_hardpoint_loadouts, path: "model-hardpoint-loadouts", only: %i[index show create update destroy]
  resources :model_loaners, path: "model-loaners", only: %i[index show create update destroy]

  resources :manufacturers, only: %i[index show create update destroy]

  resources :components, only: %i[index show create update destroy] do
    get :class_filters, on: :collection
    get :item_type_filters, on: :collection
  end

  resources :fleets, only: %i[index show create update destroy]

  resources :vehicles, only: %i[index show update destroy]

  resources :item_prices, path: "item-prices", only: %i[index show create update destroy]

  resources :search, only: %i[index]

  resource :stats, only: [] do
    get "quick-stats" => "stats#quick_stats"
    get "most-viewed-pages" => "stats#most_viewed_pages"
    get "visits-per-day" => "stats#visits_per_day"
    get "visits-per-month" => "stats#visits_per_month"
    get "registrations-per-month" => "stats#registrations_per_month"
  end

  resources :images, only: %i[index create destroy update] do
    put :attach, on: :collection
  end

  resources :imports, only: %i[index show]
end

scope :v1, as: :v1 do
  scope module: :v1, &v1_admin_api_routes
end
