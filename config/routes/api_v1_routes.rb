# frozen_string_literal: true

v1_api_routes = lambda do
  resource :sessions, only: %i[create destroy] do
    collection do
      put :renew
      delete 'destroy=all' => 'sessions#destroy_all'
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
      post :embed
    end
    member do
      get :images
      get :videos
      get :variants
      get 'snub-crafts' => 'models#snub_crafts'
      get :modules
      get :upgrades
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
      post :signup
      post :confirm
      get :current
      put 'current' => 'users#update'
      patch 'current' => 'users#update'
      delete 'current' => 'users#destroy'
      get ':username' => 'users#public'
      post 'check-email'
      post 'check-username'
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
      post :embed
      get 'hangar-items' => 'vehicles#hangar_items'
      get :hangar
      get ':username' => 'vehicles#public', as: :public
      get ':username/quick-stats' => 'vehicles#public_quick_stats', as: :public_quick_stats
      get ':username/fleetchart' => 'vehicles#public_fleetchart', as: :public_fleetchart
      get 'stats/models-by-size' => 'vehicles#models_by_size'
      get 'stats/models-by-production-status' => 'vehicles#models_by_production_status'
      get 'stats/models-by-manufacturer' => 'vehicles#models_by_manufacturer'
      get 'stats/models-by-classification' => 'vehicles#models_by_classification'
    end
  end

  resources :hangar_groups, path: 'hangar-groups', only: %i[index create update destroy] do
    collection do
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
  resources :components, only: [:index]

  resources :starsystems, param: :slug, only: %i[index show]
  resources :celestial_objects, path: 'celestial-objects', param: :slug, only: %i[index show]
  resources :stations, param: :slug, only: %i[index show] do
    collection do
      get 'ship-sizes' => 'stations#ship_sizes'
      get 'station-types' => 'stations#station_types'
    end
    member do
      get :images
    end
    resources :shops, param: :slug, only: %i[show] do
      resources :shop_commodities, path: 'shop-commodities', only: %i[index]
    end
  end

  get 'filters/shop-commodities/sub-categories' => 'shop_commodities#sub_categories'

  resources :shops, param: :slug, only: %i[index] do
    collection do
      get 'shop-types' => 'shops#shop_types'
    end
  end

  resources :fleets, param: :slug, except: %i[index] do
    member do
      get :vehicles
      get :models
      get :members
      get 'quick-stats' => 'fleets#quick_stats'
      get 'member-quick-stats' => 'fleets#member_quick_stats'
      get :fleetchart
      get 'stats/models-by-size' => 'fleets#models_by_size'
      get 'stats/models-by-production-status' => 'fleets#models_by_production_status'
      get 'stats/models-by-manufacturer' => 'fleets#models_by_manufacturer'
      get 'stats/models-by-classification' => 'fleets#models_by_classification'
    end

    resources :fleet_memberships, path: 'members', param: :username, only: %i[create destroy] do
      collection do
        put 'accept-invite' => 'fleet_memberships#accept_invite'
        put 'decline-invite' => 'fleet_memberships#decline_invite'
        delete :leave
      end
      member do
        put :demote
        put :promote
      end
    end
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
