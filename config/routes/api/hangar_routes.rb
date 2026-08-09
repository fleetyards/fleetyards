resource :hangar, only: %i[show destroy] do
  get :items
  put :import
  get :export
  get "export/hangar-link", to: "hangars#export_hangar_link"
  put "sync-rsi-hangar", to: "hangars#sync_rsi_hangar"
  get "sync-rsi-hangar/status", to: "hangars#sync_rsi_hangar_status"

  put "move-all-ingame-to-wishlist", to: "hangars#move_all_ingame_to_wishlist"

  resource :hangar_stats, path: "stats", only: %i[show] do
    get "models-by-size", to: "hangar_stats#models_by_size"
    get "models-by-production-status", to: "hangar_stats#models_by_production_status"
    get "models-by-manufacturer", to: "hangar_stats#models_by_manufacturer"
    get "models-by-classification", to: "hangar_stats#models_by_classification"
  end

  resources :hangar_groups, path: "groups", only: %i[index create update destroy] do
    put :sort, on: :collection
  end

  get "inventory-items", to: "hangar_all_inventory_items#index"
  get "inventory-stock", to: "hangar_all_inventory_stock#index"

  resources :hangar_inventories, path: "inventories", param: :slug, only: %i[index show create update destroy] do
    resources :hangar_inventory_items, path: "items", only: %i[index create update destroy] do
      post :import, on: :collection
    end
    get "stock", to: "hangar_inventory_stock#index"
  end
end

resource :wishlist, only: %i[show destroy] do
  get :items
  get :export
end

namespace :public do
  resources :hangars, param: :username, only: %i[show] do
    get :embed, on: :collection

    resource :hangar_stats, path: "stats", only: %i[show] do
      get "models-by-size", to: "hangar_stats#models_by_size"
      get "models-by-production-status", to: "hangar_stats#models_by_production_status"
      get "models-by-manufacturer", to: "hangar_stats#models_by_manufacturer"
      get "models-by-classification", to: "hangar_stats#models_by_classification"
    end
    resources :hangar_groups, path: "groups", only: %i[index]
  end

  resources :wishlists, param: :username, only: %i[show]
end
