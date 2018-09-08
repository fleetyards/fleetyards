# frozen_string_literal: true

v1_api_routes = lambda do
  resource :sessions, only: %i[create destroy]

  resources :models, param: :slug, only: %i[index show] do
    collection do
      get :latest
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
    end
  end

  resources :hangar_groups, path: 'hangar-groups', only: %i[index create update destroy]

  resources :trade_hubs, path: 'trade-hubs', only: [:index]
  resources :commodities, only: [:index]
  resources :commodity_prices, path: 'commodity-prices', only: %i[show create]

  resources :planets, param: :slug, only: %i[index]
  resources :stations, param: :slug, only: %i[index show]

  namespace :rsi do
    resources :citizens, only: [:show], param: :handle
    resources :orgs, only: %i[show], param: :sid
  end
end

scope :v1, as: :v1 do
  scope module: :v1, &v1_api_routes

  root to: 'v1/base#root'
end
