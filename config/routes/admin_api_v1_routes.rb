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

  resource :equipment, only: [] do
    get :weapons, on: :collection
    get :attachments, on: :collection
    get :utilities, on: :collection
  end

  resources :images, only: %i[index create destroy update]
end

scope :v1, as: :v1 do
  scope module: :v1, &v1_admin_api_routes
end
