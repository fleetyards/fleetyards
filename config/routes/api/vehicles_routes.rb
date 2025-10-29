resources :vehicles, only: %i[create update destroy] do
  collection do
    post "bulk", to: "vehicles#create_bulk"
    put "bulk", to: "vehicles#update_bulk"
    put "destroy-bulk", to: "vehicles#destroy_bulk"
    delete "destroy-all-ingame" => "vehicles#destroy_all_ingame"

    post "check-serial"
    get "filters/bought-via", to: "vehicles#bought_via_filters"
  end
end

namespace :filters do
  resources :vehicles, only: [] do
    get "bought-via", to: "vehicles#bought_via", on: :collection
  end
end
