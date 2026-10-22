resource :hangar, only: %i[show destroy] do
  get :items
  put :import
  get :export
  get "export/hangar-link", to: "hangars#export_hangar_link"
  put "sync-rsi-hangar", to: "hangars#sync_rsi_hangar"
  get "sync-rsi-hangar/status", to: "hangars#sync_rsi_hangar_status"
  get "sync-rsi-hangar/last-read", to: "hangars#sync_rsi_hangar_last_read"
  put "sync-rsi-buybacks", to: "hangar_buybacks#sync"
  get "sync-rsi-buybacks/last-read", to: "hangar_buybacks#sync_last_read"
  put "sync-rsi-buyback-details", to: "hangar_buybacks#sync_details"
  post "rsi-page-reports", to: "hangar_rsi_page_reports#create"
  get "buybacks", to: "hangar_buybacks#index"
  get "buybacks/insurance-terms", to: "hangar_buybacks#insurance_terms"
  delete "buybacks/:id", to: "hangar_buybacks#destroy"
  get "paints", to: "hangar_pledge_items#paints"
  get "flair", to: "hangar_pledge_items#flair"
  get "upgrades", to: "hangar_pledge_items#upgrades"
  get "equipment", to: "hangar_pledge_items#equipment"
  get "ship-components", to: "hangar_pledge_items#ship_components"
  get "blueprint-missions", to: "hangar_blueprint_missions#index"

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

  resources :hangar_inventory_transfers, path: "inventory-transfers",
    controller: "hangar_inventory_transfers", only: %i[index show create] do
    member do
      put :accept
      put :decline
      put :cancel
      post :report
    end
  end

  resources :hangar_plans, path: "plans", only: %i[index show create update destroy] do
    member do
      get :summary
      get :comparison
      get "compare/:other_id", action: :compare, as: :compare
      get :drift
      put :rebase
      put "add-to-wishlist", action: :add_to_wishlist
      put :share
      delete :share, action: :unshare
      get :resources
    end

    resources :hangar_plan_slots, path: "slots", only: %i[create update destroy] do
      put :sort, on: :collection
      put :choose, on: :member
    end
    resources :hangar_plan_candidates, path: "candidates", only: %i[create update destroy]
    resources :hangar_plan_acquisitions, path: "acquisitions", only: %i[create update destroy]
    resources :hangar_plan_melts, path: "melts", only: %i[create update destroy]
  end

  get "contract-destinations", to: "hangar_contract_destinations#index"

  get "inventory-items", to: "hangar_all_inventory_items#index"
  get "inventory-stock", to: "hangar_all_inventory_stock#index"

  resources :hangar_inventories, path: "inventories", param: :slug, only: %i[index show create update destroy] do
    resources :hangar_inventory_items, path: "items", only: %i[index create update destroy] do
      post :import, on: :collection
      post "from-pledge-items", on: :collection, to: "hangar_inventory_items#add_pledge_items"
    end
    get "stock", to: "hangar_inventory_stock#index"
    get "stock/:slug", to: "hangar_inventory_stock#show", as: "stock_item"
    patch "stock/:slug", to: "hangar_inventory_stock#update"
    delete "stock/:slug", to: "hangar_inventory_stock#destroy"
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
    resources :vehicles, controller: "hangar_vehicles", only: %i[show] do
      resources :log_entries, path: "log-entries", controller: "vehicle_log_entries", only: %i[index]
      resources :loadouts, controller: "vehicle_loadouts", only: %i[show] do
        get :slots, on: :member
      end
    end
  end

  resources :wishlists, param: :username, only: %i[show]

  resources :hangar_plans, path: "hangar-plans", param: :token, only: %i[show] do
    get :summary, on: :member
  end
end
