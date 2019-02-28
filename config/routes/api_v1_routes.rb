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
      get :modules
      get :upgrades
      get :store_image, path: 'store-image'
      get :fleetchart_image, path: 'fleetchart-image'
    end
  end

  resources :manufacturers, param: :slug, only: %i[index]

  resources :images, only: %i[index] do
    get :random, on: :collection
  end

  resources :fleets, param: :sid, only: %i[index show create destroy] do
    collection do
      get :my
    end
    member do
      get :models
      get :count
      get :members
    end
  end

  resources :users, only: [] do
    collection do
      post :signup
      post :confirm
      get :current
      put 'current' => 'users#update'
      patch 'current' => 'users#update'
      delete 'current' => 'users#destroy'
      post 'check-email'
      post 'check-username'
      post 'start-rsi-verification'
      post 'finish-rsi-verification'
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
      get :count
      get :fleetchart
      get 'hangar-items' => 'vehicles#hangar_items'
      get ':username' => 'vehicles#public', as: :public
      get ':username/count' => 'vehicles#public_count', as: :public_count
      get ':username/fleetchart' => 'vehicles#public_fleetchart', as: :public_fleetchart
    end
  end

  resources :hangar_groups, path: 'hangar-groups', only: %i[index create update destroy]

  resources :trade_hubs, path: 'trade-hubs', only: [:index]
  resources :commodities, only: [:index]
  resources :commodity_prices, path: 'commodity-prices', only: %i[show create]

  resources :starsystems, param: :slug, only: %i[index show]
  resources :celestial_objects, path: 'celestial-objects', param: :slug, only: %i[index show]
  resources :stations, param: :slug, only: %i[index show] do
    collection do
      get 'ship-sizes' => 'stations#ship_sizes'
      get 'station-types' => 'stations#station_types'
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

  namespace :rsi do
    resources :citizens, only: [:show], param: :handle
    resources :orgs, only: %i[show], param: :sid
  end

  resource :stats, only: [] do
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
