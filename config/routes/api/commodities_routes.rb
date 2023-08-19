resources :commodities, only: [:index] do
  get "types", to: "filters/commodities#commodity_types", on: :collection # DEPRECATED
end

namespace :filters do
  resources :commodities, only: [] do
    get "types", to: "commodities#commodity_types", on: :collection
  end
end
