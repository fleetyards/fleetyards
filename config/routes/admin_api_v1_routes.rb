# frozen_string_literal: true

v1_admin_api_routes = lambda do
  resources :models, only: %i[] do
    get :images, on: :member
  end

  resources :stations, only: %i[] do
    get :images, on: :member
  end

  resources :images, only: %i[create destroy update]
end

scope :v1, as: :v1 do
  scope module: :v1, &v1_admin_api_routes
end
