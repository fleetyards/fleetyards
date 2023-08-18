# frozen_string_literal: true

v1_api_routes = lambda do
  resource :sessions, only: %i[create destroy] do
    collection do
      post "confirm-access" => "sessions#confirm_access"
    end
  end

  get "sc-data/version" => "sc_data#current_version"

  resource :features, only: %i[show]

  resources :models, param: :slug, only: %i[index show] do
    collection do
      get :fleetchart
      get "with-docks" => "models#with_docks"
      get :unscheduled
      get :latest
      get :slugs
      get :updated
      get :filters
      get :classifications
      get "production-states" => "models#production_states"
      get :focus
      get :sizes
      get "cargo-options" => "models#cargo_options"
      get :embed
    end
    member do
      get :hardpoints
      get :images
      get :videos
      get :variants
      get :loaners
      get "snub-crafts" => "models#snub_crafts"
      get :modules
      get :module_packages, path: "module-packages"
      get :upgrades
      get :paints
      get :store_image, path: "store-image"
      get :fleetchart_image, path: "fleetchart-image"
    end
  end

  resources :model_paints, path: "model-paints", only: %i[index]

  resources :manufacturers, param: :slug, only: %i[index] do
    collection do
      get "with-models" => "manufacturers#with_models"
    end
  end

  resources :images, only: %i[index] do
    get :random, on: :collection
  end

  resources :roadmap, only: %i[index] do
    get :weeks, on: :collection
  end

  resources :search, only: %i[index]

  resources :users, only: [] do
    collection do
      get :me
      post :signup
      post :confirm
      post "check-email"
      post "check-username"
      put "current", to: "users#update"
      patch "current", to: "users#update"
      put "current-account", to: "users#update_account"
      patch "current-account", to: "users#update_account"
      delete "current", to: "users#destroy"

      get :current, to: "users#me" # DEPRECATED

      get ":username", to: "users#public"

      resource :two_factor, path: "two-factor", only: [] do
        collection do
          get :qrcode
          post :start
          post :enable
          post :disable
          post "generate-backup-codes" => "two_factors#generate_backup_codes"
        end
      end
    end
  end

  resource :password, only: [:update] do
    collection do
      post "request", to: "passwords#request_email"
      patch "update", to: "passwords#update"
      put "update", to: "passwords#update"
      patch "update/:reset_password_token", to: "passwords#update_with_token"
      put "update/:reset_password_token", to: "passwords#update_with_token"
    end
  end

  resource :hangar, only: %i[show destroy] do
    get :items
    put :import
    get :export
    put "sync-rsi-hangar", to: "hangars#sync_rsi_hangar"

    put "move-all-ingame-to-wishlist", to: "hangars#move_all_ingame_to_wishlist"

    resource :hangar_stats, path: "stats", only: %i[show] do
      get "models-by-size", to: "hangar_stats#models_by_size"
      get "models-by-production-status", to: "hangar_stats#models_by_production_status"
      get "models-by-manufacturer", to: "hangar_stats#models_by_manufacturer"
      get "models-by-classification", to: "hangar_stats#models_by_classification"
    end

    resources :hangar_groups, path: "groups", only: %i[index create update destroy] do
      collection do
        put :sort
      end
    end
  end

  resource :wishlist, only: %i[show destroy] do
    get :items
    get :export
  end

  namespace :public do
    resources :hangars, param: :username, only: %i[show] do
      collection do
        get :embed
      end

      resource :hangar_stats, path: "stats", only: %i[show]
      resources :hangar_groups, path: "groups", only: %i[index]
    end

    resources :wishlists, param: :username, only: %i[show]

    resources :fleets, param: :slug, only: %i[] do
      resources :fleet_vehicles, path: "vehicles", only: %i[index] do
        get :embed, on: :collection
      end

      resource :fleet_stats, path: "stats", only: %i[] do
        # get "vehicles", to: "fleet_stats#vehicles"
        get "model-counts", to: "fleet_stats#model_counts"
        # get "members", to: "fleet_stats#members"
        # get "vehicles-by-model", to: "fleet_stats#vehicles_by_model"
        # get "models-by-size", to: "fleet_stats#models_by_size"
        # get "models-by-production-status", to: "fleet_stats#models_by_production_status"
        # get "models-by-manufacturer", to: "fleet_stats#models_by_manufacturer"
        # get "models-by-classification", to: "fleet_stats#models_by_classification"
      end
    end
  end

  resources :vehicles, only: %i[create update destroy] do
    collection do
      put "bulk", to: "vehicles#update_bulk"
      put "destroy-bulk", to: "vehicles#destroy_bulk"
      delete "destroy-all-ingame" => "vehicles#destroy_all_ingame"

      post "check-serial"
      get "filters/bought-via", to: "vehicles#bought_via_filters"

      # DEPRECATED
      get "/", to: "hangars#show"
      get :fleetchart
      get ":username/fleetchart", to: "vehicles#public_fleetchart", as: :public_fleetchart

      get "wishlist", to: "wishlists#show"
      get "quick-stats", to: "hangar_stats#show"
      get "export", to: "hangars#export"
      get "export-wishlist", to: "wishlists#export"
      put "import", to: "hangars#import"

      put "move-all-ingame-to-wishlist", to: "hangars#move_all_ingame_to_wishlist"
      delete "destroy-all", to: "hangars#destroy"
      delete "destroy-all-wishlist", to: "wishlists#destroy"
      get "embed", to: "public/hangars#embed"
      get "hangar-items", to: "hangars#items"
      get "wishlist-items", to: "wishlists#items"
      get "hangar", to: "vehicles#hangar"
      get ":username", to: "public/hangars#show", as: :public
      get ":hangar_username/quick-stats", to: "public/hangar_stats#show", as: :public_quick_stats
      get ":username/wishlist", to: "public/wishlists#show", as: :public_wishlist
      get "stats/models-by-size", to: "hangar_stats#models_by_size"
      get "stats/models-by-production-status", to: "hangar_stats#models_by_production_status"
      get "stats/models-by-manufacturer", to: "hangar_stats#models_by_manufacturer"
      get "stats/models-by-classification", to: "hangar_stats#models_by_classification"
    end
  end

  # DEPRECATED
  resources :hangar_groups, path: "hangar-groups", only: %i[index create update destroy] do
    collection do
      get ":hangar_username" => "public/hangar_groups#index", :as => :public
      put :sort
    end
  end

  resources :trade_routes, path: "trade-routes", only: [:index]
  resources :commodities, only: [:index] do
    collection do
      get "types" => "commodities#commodity_types"
    end
  end
  resources :equipment, only: [:index]
  resources :components, only: [:index] do
    get :class_filters, on: :collection
    get :item_type_filters, on: :collection
  end

  resources :starsystems, param: :slug, only: %i[index show]
  resources :celestial_objects, path: "celestial-objects", param: :slug, only: %i[index show]
  resources :stations, param: :slug, only: %i[index show] do
    collection do
      get "ship-sizes" => "stations#ship_sizes"
      get "station-types" => "stations#station_types"
      get "classifications" => "stations#classifications"
    end
    member do
      get :images
    end
    resources :shops, param: :slug, only: %i[show] do
      resources :shop_commodities, path: "commodities", only: %i[index]
    end
  end

  resources :commodity_prices, path: "commodity-prices", only: [:create] do
    collection do
      get "time-ranges" => "commodity_prices#time_ranges"
    end
  end

  get "shop-commodities/commodity-type-options" => "shop_commodities#commodity_item_types"
  get "filters/shop-commodities/sub-categories" => "shop_commodities#sub_categories"

  resources :shops, param: :slug, only: %i[index] do
    collection do
      get "shop-types" => "shops#shop_types"
    end
  end

  resources :fleets, param: :slug, only: %i[show create update destroy] do
    collection do
      post :check
      get :invites
      get :my
      get "check-invite/:token", to: "fleet_invite_urls#check"
      post "use-invite", to: "fleet_invite_urls#use"
    end

    resources :fleet_vehicles, path: "vehicles", only: %i[index] do
      get :export, on: :collection
    end

    delete "members/leave", to: "fleet_memberships#destroy" # DEPRECATED

    resources :fleet_members, path: "members", param: :username, only: %i[index create destroy] do
      member do
        put :demote
        put :promote
        put :accept
        put :decline
      end
    end

    resource :fleet_membership, path: "membership", only: %i[show create update destroy] do
      put :accept
      put :decline
    end

    resources :fleet_invite_urls, path: "invite-urls", param: :token, only: %i[index create destroy]

    resource :fleet_stats, path: "stats", only: %i[] do
      get "model-counts", to: "fleet_stats#model_counts"
      get "vehicles", to: "fleet_stats#vehicles"
      get "members", to: "fleet_stats#members"
      get "vehicles-by-model", to: "fleet_stats#vehicles_by_model"
      get "models-by-size", to: "fleet_stats#models_by_size"
      get "models-by-production-status", to: "fleet_stats#models_by_production_status"
      get "models-by-manufacturer", to: "fleet_stats#models_by_manufacturer"
      get "models-by-classification", to: "fleet_stats#models_by_classification"
    end

    # DEPRECATED
    get :current, to: "fleets#my", on: :collection
    get "fleetchart", to: "fleet_vehicles#fleetchart"
    get "public-vehicles", to: "public/fleet_vehicles#index"
    get "embed", to: "public/fleet_vehicles#embed"
    get "public-fleetchart", to: "public/fleet_vehicles#fleetchart"
    put "members/:username/accept-request", to: "fleet_members#accept"
    put "members/:username/decline-request", to: "fleet_members#decline"
    put "members/accept-invite", to: "fleet_memberships#accept"
    put "members/decline-invite", to: "fleet_memberships#decline"
    get "members/current", to: "fleet_memberships#show"
    put "members", to: "fleet_memberships#update"
    patch "members", to: "fleet_memberships#update"
    get "model-counts", to: "fleet_stats#model_counts"
    get "quick-stats", to: "fleet_stats#vehicles"
    get "member-quick-stats", to: "fleet_stats#members"
    get "stats/vehicles-by-model", to: "fleet_stats#vehicles_by_model"
    get "stats/models-by-size", to: "fleet_stats#models_by_size"
    get "stats/models-by-production-status", to: "fleet_stats#models_by_production_status"
    get "stats/models-by-manufacturer", to: "fleet_stats#models_by_manufacturer"
    get "stats/models-by-classification", to: "fleet_stats#models_by_classification"
    get "public-model-counts", to: "public/fleet_stats#model_counts"
  end

  resource :stats, only: [] do
    get "quick-stats" => "stats#quick_stats"
    get "models-per-month" => "stats#models_per_month"
    get "models-by-size" => "stats#models_by_size"
    get "models-by-production-status" => "stats#models_by_production_status"
    get "models-by-manufacturer" => "stats#models_by_manufacturer"
    get "models-by-classification" => "stats#models_by_classification"
    get "components-by-class" => "stats#components_by_class"
  end

  get "version" => "base#version"
end

scope :v1, as: :v1 do
  scope module: :v1, &v1_api_routes

  root to: "v1/base#root"
end
