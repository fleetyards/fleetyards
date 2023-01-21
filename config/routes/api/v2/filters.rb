# frozen_string_literal: true

namespace :filters do
  resources :models, only: [] do
    get :slugs, on: :collection
    get :filters, on: :collection
    get :classifications, on: :collection
    get :production_states, path: "production-states", on: :collection
    get :focus, on: :collection
    get :sizes, on: :collection
  end

  resources :shop_commodities, path: "shop-commodities", only: [] do
    get :sub_categories, path: "sub-categories", on: :collection
    get :commodity_item_types, path: "commodity-type-options", on: :collection
  end

  resources :commodities, only: [] do
    get :commodity_types, path: "types", on: :collection
  end

  resources :commodity_prices, path: "commodity-prices", only: [] do
    get :time_ranges, path: "time-ranges", on: :collection
  end

  resources :shops, only: [] do
    get :shop_types, path: "shop-types", on: :collection
  end

  resources :stations, only: [] do
    get :ship_sizes, path: "ship-sizes", on: :collection
    get :station_types, path: "station-types", on: :collection
    get :classifications, on: :collection
  end
end
