resources :fleets, param: :slug, only: %i[show create update destroy] do
  collection do
    post :check
    get :invites
    get :my
    post "use-invite", to: "fleet_invite_urls#use"
    post "find-by-invite/:token", to: "fleets#find_by_invite"
  end

  resources :fleet_vehicles, path: "vehicles", only: %i[index] do
    get :export, on: :collection
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
      # get "vehicles-by-model", to: "fleet_stats#vehicles_by_model"
      # get "models-by-size", to: "fleet_stats#models_by_size"
      # get "models-by-production-status", to: "fleet_stats#models_by_production_status"
      # get "models-by-manufacturer", to: "fleet_stats#models_by_manufacturer"
      # get "models-by-classification", to: "fleet_stats#models_by_classification"
    end
  end
end
