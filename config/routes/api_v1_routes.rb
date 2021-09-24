# frozen_string_literal: true

v1_api_routes = lambda do
  resource :sessions, only: %i[create destroy] do
    collection do
      post 'confirm-access' => 'sessions#confirm_access'
    end
  end

  resources :models, param: :slug, only: %i[index show] do
    collection do
      get :fleetchart
      get 'with-docks' => 'models#with_docks'
      get :unscheduled
      get :latest
      get :slugs
      get :updated
      get :filters
      get :classifications
      get 'production-states' => 'models#production_states'
      get :focus
      get :sizes
      get 'cargo-options' => 'models#cargo_options'
      get :embed
    end
    member do
      get :hardpoints
      get :images
      get :videos
      get :variants
      get :loaners
      get 'snub-crafts' => 'models#snub_crafts'
      get :modules
      get :upgrades
      get :paints
      get :store_image, path: 'store-image'
      get :fleetchart_image, path: 'fleetchart-image'
    end
  end

  resources :manufacturers, param: :slug, only: %i[index] do
    collection do
      get 'with-models' => 'manufacturers#with_models'
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
      get :current
      post :signup
      post :confirm
      post 'check-email'
      post 'check-username'
      put 'current' => 'users#update'
      patch 'current' => 'users#update'
      put 'current-account' => 'users#update_account'
      patch 'current-account' => 'users#update_account'
      delete 'current' => 'users#destroy'

      get ':username' => 'users#public'

      resource :two_factor, path: 'two-factor', only: [] do
        collection do
          get :qrcode
          post :enable
          post :disable
          post 'generate-backup-codes' => 'two_factors#generate_backup_codes'
        end
      end
    end
  end

  resource :password, only: [:update] do
    collection do
      post 'request' => 'passwords#request_email'
      patch 'update' => 'passwords#update'
      put 'update' => 'passwords#update'
      patch 'update/:reset_password_token' => 'passwords#update_with_token'
      put 'update/:reset_password_token' => 'passwords#update_with_token'
    end
  end

  resources :vehicles, except: [:show] do
    collection do
      get 'quick-stats' => 'vehicles#quick_stats'
      get :fleetchart
      get :export
      put :import
      put 'bulk' => 'vehicles#update_bulk'
      put 'destroy-bulk' => 'vehicles#destroy_bulk'
      delete 'destroy-all' => 'vehicles#destroy_all'
      get :embed
      get 'hangar-items' => 'vehicles#hangar_items'
      get :hangar
      get ':username' => 'vehicles#public', as: :public
      get ':username/quick-stats' => 'vehicles#public_quick_stats', as: :public_quick_stats
      get ':username/fleetchart' => 'vehicles#public_fleetchart', as: :public_fleetchart
      get 'stats/models-by-size' => 'vehicles#models_by_size'
      get 'stats/models-by-production-status' => 'vehicles#models_by_production_status'
      get 'stats/models-by-manufacturer' => 'vehicles#models_by_manufacturer'
      get 'stats/models-by-classification' => 'vehicles#models_by_classification'
      post 'check-serial'
    end
  end

  resources :hangar_groups, path: 'hangar-groups', only: %i[index create update destroy] do
    collection do
      get :public
      put :sort
    end
  end

  resources :trade_routes, path: 'trade-routes', only: [:index]
  resources :commodities, only: [:index] do
    collection do
      get 'types' => 'commodities#commodity_types'
    end
  end
  resources :equipment, only: [:index]
  resources :components, only: [:index] do
    get :class_filters, on: :collection
    get :item_type_filters, on: :collection
  end

  resources :starsystems, param: :slug, only: %i[index show]
  resources :celestial_objects, path: 'celestial-objects', param: :slug, only: %i[index show]
  resources :stations, param: :slug, only: %i[index show] do
    collection do
      get 'ship-sizes' => 'stations#ship_sizes'
      get 'station-types' => 'stations#station_types'
      get 'classifications' => 'stations#classifications'
    end
    member do
      get :images
    end
    resources :shops, param: :slug, only: %i[show] do
      resources :shop_commodities, path: 'commodities', only: %i[index]
    end
  end

  resources :commodity_prices, path: 'commodity-prices', only: [:create] do
    collection do
      get 'time-ranges' => 'commodity_prices#time_ranges'
    end
  end

  get 'shop-commodities/commodity-type-options' => 'shop_commodities#commodity_item_types'
  get 'filters/shop-commodities/sub-categories' => 'shop_commodities#sub_categories'

  resources :shops, param: :slug, only: %i[index] do
    collection do
      get 'shop-types' => 'shops#shop_types'
    end
  end

  resources :fleets, param: :slug, except: %i[index] do
    collection do
      post :check
      get :invites
      get :current
      post 'use-invite' => 'fleet_memberships#create_by_invite'
    end

    member do
      get 'vehicles' => 'fleet_vehicles#index'
      get 'quick-stats' => 'fleet_vehicles#quick_stats'
      get 'fleetchart' => 'fleet_vehicles#fleetchart'
      get 'public-vehicles' => 'fleet_vehicles#public'
      get 'public-fleetchart' => 'fleet_vehicles#public_fleetchart'

      get 'members' => 'fleet_members#index'
      get 'member-quick-stats' => 'fleet_members#quick_stats'

      get 'stats/models-by-size' => 'fleet_stats#models_by_size'
      get 'stats/models-by-production-status' => 'fleet_stats#models_by_production_status'
      get 'stats/models-by-manufacturer' => 'fleet_stats#models_by_manufacturer'
      get 'stats/models-by-classification' => 'fleet_stats#models_by_classification'
    end

    resources :fleet_memberships, path: 'members', param: :username, only: %i[create destroy] do
      collection do
        get :current
        put :update
        patch :update
        put 'accept-invite' => 'fleet_memberships#accept_invite'
        put 'decline-invite' => 'fleet_memberships#decline_invite'
        delete :leave
        post 'create-by-invite' => 'fleet_memberships#create_by_invite'
      end
      member do
        put :demote
        put :promote
        put 'accept-request' => 'fleet_memberships#accept_request'
        put 'decline-request' => 'fleet_memberships#decline_request'
      end
    end

    resources :fleet_invite_urls, path: 'invite-urls', param: :token, only: %i[index create destroy]
  end

  resource :stats, only: [] do
    get 'quick-stats' => 'stats#quick_stats'
    get 'models-per-month' => 'stats#models_per_month'
    get 'models-by-size' => 'stats#models_by_size'
    get 'models-by-production-status' => 'stats#models_by_production_status'
    get 'models-by-manufacturer' => 'stats#models_by_manufacturer'
    get 'models-by-classification' => 'stats#models_by_classification'
    get 'components-by-class' => 'stats#components_by_class'
  end

  get 'version' => 'base#version'
end

scope :v1, as: :v1 do
  scope module: :v1, &v1_api_routes

  root to: 'v1/base#root'
end
