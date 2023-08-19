resources :commodity_prices, path: "commodity-prices", only: [:create] do
  get "time-ranges", to: "filters/commodity_prices#time_ranges", on: :collection # DEPRECATED
end

namespace :filters do
  resources :commodity_prices, path: "commodity-prices", only: [] do
    get "time-ranges", to: "commodity_prices#time_ranges", on: :collection
  end
end
