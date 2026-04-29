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
      put "reload-one-matrix" => "models#reload_one_matrix"
      put "reload-one-scdata" => "models#reload_one_scdata"
    end
  end

  resources :videos, only: %i[index show create update destroy]
  resources :model_modules, path: "model-modules", only: %i[index show create update destroy] do
    collection do
      put "bulk", to: "model_modules#update_bulk"
      delete "bulk", to: "model_modules#destroy_bulk"
    end
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
  resources :model_positions, path: "model-positions", only: %i[index show create update destroy] do
    collection do
      put :regenerate
    end
  end
  resources :docks, only: %i[index show create update destroy]
  resources :model_hardpoints, path: "model-hardpoints", only: %i[index show create update destroy]
  resources :model_hardpoint_loadouts, path: "model-hardpoint-loadouts", only: %i[index show create update destroy]
  resources :model_loaners, path: "model-loaners", only: %i[index show create update destroy]
  resources :cargo_holds, path: "cargo-holds", only: %i[index show update]

  resources :manufacturers, only: %i[index show create update destroy]

  resources :components, only: %i[index show create update destroy] do
    get :class_filters, on: :collection
    get :item_type_filters, on: :collection
  end

  resources :fleets, only: %i[index show create update destroy] do
    resources :fleet_members, path: "members", only: %i[index] do
      member do
        get "login-as", to: "fleet_members#login_as"
      end
    end
  end

  resources :vehicles, only: %i[index show update destroy]

  resources :item_prices, path: "item-prices", only: %i[index show create update destroy]

  resource :stats, only: [] do
    get "quick-stats" => "stats#quick_stats"
    get "most-viewed-pages" => "stats#most_viewed_pages"
    get "visits-per-day" => "stats#visits_per_day"
    get "visits-per-month" => "stats#visits_per_month"
    get "registrations-per-month" => "stats#registrations_per_month"
  end

  resources :images, only: %i[index create destroy update] do
    collection do
      put :attach
      put "bulk", to: "images#update_bulk"
    end
  end

  resources :imports, only: %i[index show]

  resources :oauth_applications, path: "oauth-applications", only: %i[index show create update destroy]

  resources :rsi_request_logs, path: "rsi-request-logs", only: %i[index] do
    member do
      put :resolve
    end
  end

  resources :features, only: %i[index show create destroy] do
    member do
      put :enable
      put :disable
      put "enable-actor", to: "features#enable_actor"
      put "disable-actor", to: "features#disable_actor"
      put "enable-group", to: "features#enable_group"
      put "disable-group", to: "features#disable_group"
      put "enable-percentage-of-actors", to: "features#enable_percentage_of_actors"
      put "enable-percentage-of-time", to: "features#enable_percentage_of_time"
      put "toggle-self-service", to: "features#toggle_self_service"
    end
  end
end

scope :v1, as: :v1 do
  scope module: :v1, &v1_admin_api_routes
end
