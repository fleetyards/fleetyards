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

  resource :stats, only: [] do
    get 'quick-stats' => 'stats#quick_stats'
    get 'most-viewed-pages' => 'stats#most_viewed_pages'
    get 'visits-per-day' => 'stats#visits_per_day'
    get 'visits-per-month' => 'stats#visits_per_month'
    get 'registrations-per-month' => 'stats#registrations_per_month'
  end

  resources :images, only: %i[index create destroy update]
end

scope :v1, as: :v1 do
  scope module: :v1, &v1_admin_api_routes
end
