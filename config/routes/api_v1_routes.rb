# encoding: utf-8
# frozen_string_literal: true

v1_api_routes = lambda do
  resource :sessions, only: %i[create destroy]

  resources :ships, param: :slug, only: %i[index show] do
    get 'latest', on: :collection
    get 'filters', on: :collection
    get 'gallery', on: :member
  end

  resources :images, only: %i[index] do
    get 'latest', on: :collection
  end

  resources :users, only: [] do
    collection do
      post :signup
      post :confirm
      get :current
    end
  end

  resource :hangar, only: [:show] do
    collection do
      get ':username' => 'hangars#public', as: :public
    end
  end
  resources :my_ships, path: 'my-ships', only: %i[create update destroy]
end

scope :v1, defaults: { format: :json }, as: :v1 do
  scope module: :v1, &v1_api_routes
end
