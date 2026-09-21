resources :commodities, param: :slug, only: %i[index show] do
  member do
    get :price_history, path: "price-history"
  end
end

namespace :filters do
  resources :commodities, only: [] do
    get :types, on: :collection
  end
end
