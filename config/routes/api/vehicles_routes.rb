resources :vehicles, only: %i[create update destroy] do
  collection do
    put "bulk", to: "vehicles#update_bulk"
    put "destroy-bulk", to: "vehicles#destroy_bulk"
    delete "destroy-all-ingame" => "vehicles#destroy_all_ingame"

    post "check-serial"
    get "filters/bought-via", to: "vehicles#bought_via_filters"
  end
end
