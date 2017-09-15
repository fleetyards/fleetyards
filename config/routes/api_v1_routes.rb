# encoding: utf-8
# frozen_string_literal: true

v1_api_routes = lambda do
  resource :sessions, only: %i[create destroy]

  resources :ships, param: :slug, only: %i[index show] do
    collection do
      get :latest
      get :updated
      get :filters
    end
    get 'gallery', on: :member
  end

  resources :components, only: [] do
    get :categories, on: :collection
  end

  resources :images, only: %i[index] do
    get :random, on: :collection
  end

  resources :users, only: [] do
    collection do
      post :signup
      post :confirm
      get :current
      put 'current' => 'users#update'
      patch 'current' => 'users#update'
    end
  end

  resource :password, only: [:update] do
    collection do
      post 'request' => 'passwords#request_email'
      patch 'update/:reset_password_token' => 'passwords#update_with_token'
      put 'update/:reset_password_token' => 'passwords#update_with_token'
    end
  end

  resource :hangar, only: [:show] do
    collection do
      get ':username' => 'hangars#public', as: :public
    end
  end
  resources :my_ships, path: 'my-ships', only: %i[create update destroy]

  get 'rsi/citizens/:handle' => 'rsi#citizen'
  get 'rsi/orgs/:sid' => 'rsi#org'
end

scope :v1, as: :v1 do
  scope module: :v1, &v1_api_routes

  root to: "v1/base#root"
end
