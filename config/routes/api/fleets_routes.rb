resources :fleets, param: :slug, only: %i[show create update destroy] do
  collection do
    post :check
    get :invites
    get :my
    get "check-invite/:token", to: "fleet_invite_urls#check"
    post "use-invite", to: "fleet_invite_urls#use"
  end

  resources :fleet_vehicles, path: "vehicles", only: %i[index] do
    get :export, on: :collection
  end

  delete "members/leave", to: "fleet_memberships#destroy" # DEPRECATED

  resources :fleet_members, path: "members", param: :username, only: %i[index create destroy] do
    member do
      put :demote
      put :promote
      put :accept
      put :decline
    end
  end

  resource :fleet_membership, path: "membership", only: %i[show create update destroy] do
    put :accept
    put :decline
  end

  resources :fleet_invite_urls, path: "invite-urls", param: :token, only: %i[index create destroy]

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

  # DEPRECATED
  get :current, to: "fleets#my", on: :collection
  get "fleetchart", to: "fleet_vehicles#fleetchart"
  get "public-vehicles", to: "public/fleet_vehicles#index"
  get "embed", to: "public/fleet_vehicles#embed"
  get "public-fleetchart", to: "public/fleet_vehicles#fleetchart"
  put "members/:username/accept-request", to: "fleet_members#accept"
  put "members/:username/decline-request", to: "fleet_members#decline"
  put "members/accept-invite", to: "fleet_memberships#accept"
  put "members/decline-invite", to: "fleet_memberships#decline"
  get "members/current", to: "fleet_memberships#show"
  put "members", to: "fleet_memberships#update"
  get "model-counts", to: "fleet_stats#model_counts"
  get "quick-stats", to: "fleet_stats#vehicles"
  get "member-quick-stats", to: "fleet_stats#members"
  get "stats/vehicles-by-model", to: "fleet_stats#vehicles_by_model"
  get "stats/models-by-size", to: "fleet_stats#models_by_size"
  get "stats/models-by-production-status", to: "fleet_stats#models_by_production_status"
  get "stats/models-by-manufacturer", to: "fleet_stats#models_by_manufacturer"
  get "stats/models-by-classification", to: "fleet_stats#models_by_classification"
  get "public-model-counts", to: "public/fleet_stats#model_counts"
end

namespace :public do
  resources :fleets, param: :slug, only: %i[] do
    resources :fleet_vehicles, path: "vehicles", only: %i[index] do
      get :embed, on: :collection
    end

    resource :fleet_stats, path: "stats", only: %i[] do
      # get "vehicles", to: "fleet_stats#vehicles"
      get "model-counts", to: "fleet_stats#model_counts"
      # get "members", to: "fleet_stats#members"
      # get "vehicles-by-model", to: "fleet_stats#vehicles_by_model"
      # get "models-by-size", to: "fleet_stats#models_by_size"
      # get "models-by-production-status", to: "fleet_stats#models_by_production_status"
      # get "models-by-manufacturer", to: "fleet_stats#models_by_manufacturer"
      # get "models-by-classification", to: "fleet_stats#models_by_classification"
    end
  end
end
