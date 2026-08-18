resources :fleets, param: :slug, only: %i[show create update destroy] do
  collection do
    post :check
    get :invites
    get :my
    post "use-invite", to: "fleet_invite_urls#use"
    post "find-by-invite/:token", to: "fleets#find_by_invite"
  end

  resources :fleet_vehicles, path: "vehicles", only: %i[index] do
    collection do
      get :export
      get "export/hangar-link", to: "fleet_vehicles#export_hangar_link"
    end
  end

  resources :fleet_members, path: "members", param: :username, only: %i[index create destroy] do
    member do
      put :demote
      put :promote
      put :accept, to: "fleet_members#accept_request"
      put :decline, to: "fleet_members#decline_request"
    end
  end

  resource :fleet_membership, path: "membership", only: %i[show update destroy] do
    put :accept, to: "fleet_memberships#accept_invitation"
    put :decline, to: "fleet_memberships#decline_invitation"
  end

  resources :fleet_invite_urls, path: "invite-urls", param: :token, only: %i[index create destroy]

  resources :fleet_roles, path: "roles", only: %i[index]

  resources :fleet_features, path: "features", only: %i[index] do
    member do
      put :enable
      put :disable
    end
  end

  get "inventory-items", to: "fleet_all_inventory_items#index"
  get "inventory-stock", to: "fleet_all_inventory_stock#index"

  resources :fleet_inventories, path: "inventories", param: :slug, only: %i[index show create update destroy] do
    resources :fleet_inventory_items, path: "items", only: %i[index create update destroy] do
      post :import, on: :collection
    end
    get "stock", to: "fleet_inventory_stock#index"
    get "stock/:slug", to: "fleet_inventory_stock#show", as: "stock_item"
    patch "stock/:slug", to: "fleet_inventory_stock#update"
    delete "stock/:slug", to: "fleet_inventory_stock#destroy"
  end

  resources :missions, param: :slug, only: %i[index show create update destroy] do
    put :unarchive, on: :member
    resources :mission_teams, path: "teams", only: %i[create update destroy] do
      put :sort, on: :collection
      resources :mission_ships, path: "ships", only: %i[create update destroy] do
        put :sort, on: :collection
      end
    end
  end

  resource :fleet_stats, path: "stats", only: %i[] do
    get "model-counts", to: "fleet_stats#model_counts"
    get "vehicles", to: "fleet_stats#vehicles"
    get "members", to: "fleet_stats#members"
    get "vehicles-by-model", to: "fleet_stats#vehicles_by_model"
    get "models-by-size", to: "fleet_stats#models_by_size"
    get "models-by-production-status", to: "fleet_stats#models_by_production_status"
    get "models-by-manufacturer", to: "fleet_stats#models_by_manufacturer"
    get "models-by-classification", to: "fleet_stats#models_by_classification"
  end
end

namespace :public do
  resources :fleets, param: :slug, only: %i[show] do
    resources :fleet_vehicles, path: "vehicles", only: %i[index] do
      get :embed, on: :collection
    end

    resource :fleet_stats, path: "stats", only: %i[] do
      get "vehicles", to: "fleet_stats#vehicles"
      get "model-counts", to: "fleet_stats#model_counts"
      get "members", to: "fleet_stats#members"
      get "vehicles-by-model", to: "fleet_stats#vehicles_by_model"
      get "models-by-size", to: "fleet_stats#models_by_size"
      get "models-by-production-status", to: "fleet_stats#models_by_production_status"
      get "models-by-manufacturer", to: "fleet_stats#models_by_manufacturer"
      get "models-by-classification", to: "fleet_stats#models_by_classification"
    end
  end
end
