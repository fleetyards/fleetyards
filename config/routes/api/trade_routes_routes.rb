resources :trade_routes, path: "trade-routes", only: %i[index]

namespace :filters do
  resources :trade_routes, path: "trade-routes", only: [] do
    collection do
      get :star_systems, path: "star-systems"
      get :terminals
      get :origin_terminals, path: "origin-terminals"
      get :destination_terminals, path: "destination-terminals"
      get :commodities
    end
  end
end
