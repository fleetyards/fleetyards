resources :vehicles, only: %i[create update destroy] do
  collection do
    put "bulk", to: "vehicles#update_bulk"
    put "destroy-bulk", to: "vehicles#destroy_bulk"
    delete "destroy-all-ingame" => "vehicles#destroy_all_ingame"

    post "check-serial"
    get "filters/bought-via", to: "vehicles#bought_via_filters"

    # DEPRECATED
    get "/", to: "hangars#show"
    get :fleetchart
    get ":username/fleetchart", to: "/api/v1/public/vehicles#fleetchart", as: :public_fleetchart

    get "wishlist", to: "wishlists#show"
    get "quick-stats", to: "hangar_stats#show"
    get "export", to: "hangars#export"
    get "export-wishlist", to: "wishlists#export"
    put "import", to: "hangars#import"

    put "move-all-ingame-to-wishlist", to: "hangars#move_all_ingame_to_wishlist"
    delete "destroy-all", to: "hangars#destroy"
    delete "destroy-all-wishlist", to: "wishlists#destroy"
    get "embed", to: "public/hangars#embed"
    get "hangar-items", to: "hangars#items"
    get "wishlist-items", to: "wishlists#items"
    get "hangar", to: "vehicles#hangar"
    get ":username", to: "public/hangars#show", as: :public
    get ":hangar_username/quick-stats", to: "public/hangar_stats#show", as: :public_quick_stats
    get ":username/wishlist", to: "public/wishlists#show", as: :public_wishlist
    get "stats/models-by-size", to: "hangar_stats#models_by_size"
    get "stats/models-by-production-status", to: "hangar_stats#models_by_production_status"
    get "stats/models-by-manufacturer", to: "hangar_stats#models_by_manufacturer"
    get "stats/models-by-classification", to: "hangar_stats#models_by_classification"
  end
end
