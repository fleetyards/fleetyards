resources :commodities, only: [:index]

namespace :filters do
  resources :commodities, only: [] do
    get :types, on: :collection
  end
end
