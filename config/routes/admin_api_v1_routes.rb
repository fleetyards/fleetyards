# frozen_string_literal: true

v1_admin_api_routes = lambda do
  resources :models, only: %i[index] do
    get :options, on: :collection
    get :images, on: :member
  end

  resources :stations, only: %i[index] do
    get :options, on: :collection
    get :images, on: :member
  end

  resources :images, only: %i[index create destroy update] do
    get :galleries, on: :collection
  end
end

scope :v1, as: :v1 do
  scope module: :v1, &v1_admin_api_routes
end
