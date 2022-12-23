# frozen_string_literal: true

resources :celestial_objects, path: 'celestial-objects', param: :slug, only: %i[index show]

resources :commodities, only: [:index]

resources :commodity_prices, path: 'commodity-prices', only: [:create]

resources :shops, param: :slug, only: %i[index]

resources :starsystems, param: :slug, only: %i[index show]

resources :stations, param: :slug, only: %i[index show] do
  member do
    get :images
  end
  resources :shops, param: :slug, only: %i[show] do
    resources :shop_commodities, path: 'commodities', only: %i[index]
  end
end
