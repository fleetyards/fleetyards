resources :shops, only: %i[index] do
  get "shop-types", to: "filters/shops#types", on: :collection # DEPRECATED
end

namespace :filters do
  resources :shops, only: %i[] do
    get "types", to: "shops#types", on: :collection
  end
end
