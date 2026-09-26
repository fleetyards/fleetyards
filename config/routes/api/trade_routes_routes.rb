resources :trade_routes, path: "trade-routes", only: %i[index]

namespace :filters do
  resources :trade_routes, path: "trade-routes", only: [] do
    collection do
      get :star_systems, path: "star-systems"
      get :terminals
    end
  end
end
