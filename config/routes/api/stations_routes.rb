resources :stations, param: :slug, only: %i[index show] do
  get "ship-sizes", to: "stations#ship_sizes", on: :collection
  get "station-types", to: "stations#station_types", on: :collection
  get "classifications", to: "stations#classifications", on: :collection

  get :images, on: :member

  resources :shops, param: :slug, only: %i[show] do
    resources :shop_commodities, path: "commodities", only: %i[index]
  end
end

resources :shops, param: :slug, only: %i[index] do
  get "shop-types", to: "shops#shop_types", on: :collection
end

resources :shop_commodities, path: "shop-commodities", only: %i[index] do
  get "commodity-type-options", to: "shop_commodities#commodity_item_types", on: :collection
  get "sub-categories", to: "shop_commodities#sub_categories", on: :collection
end
