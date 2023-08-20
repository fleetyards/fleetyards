resources :stations, param: :slug, only: %i[index show] do
  get "ship-sizes", to: "stations#ship_sizes", on: :collection
  get "station-types", to: "stations#station_types", on: :collection
  get "classifications", to: "stations#classifications", on: :collection

  get :images, on: :member

  resources :shops, param: :slug, only: %i[show] do
    resources :shop_commodities, path: "commodities", only: %i[index]
  end
end
