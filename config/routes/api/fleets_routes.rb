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

  resources :fleet_roles, path: "roles", only: %i[index]

  resource :fleet_notification_setting, path: "notifications", only: %i[show update] do
    get "discord-status", action: :discord_status
  end

  get "inventory-items", to: "fleet_all_inventory_items#index"
  get "inventory-stock", to: "fleet_all_inventory_stock#index"

  resources :fleet_inventories, path: "inventories", param: :slug, only: %i[index show create update destroy] do
    resources :fleet_inventory_items, path: "items", only: %i[index create update destroy] do
      post :import, on: :collection
    end
    get "stock", to: "fleet_inventory_stock#index"
  end

  resources :missions, param: :slug, only: %i[index show create update destroy] do
    resources :mission_teams, path: "teams", only: %i[create update destroy] do
      put :sort, on: :collection
      resources :mission_ships, path: "ships", only: %i[create update destroy] do
        put :sort, on: :collection
      end
    end
    resources :fleet_events, path: "events", only: %i[create]
  end

  get "calendar", to: "fleet_calendars#show"
  get "events.ics", to: "fleet_calendars#ics", as: :calendar_feed, defaults: {format: "ics"}, constraints: {format: "ics"}

  resource :calendar_subscription, path: "calendar/subscription", only: %i[show create destroy] do
    post :rotate
  end

  resources :fleet_events, path: "events", param: :slug, only: %i[index show create update destroy], constraints: {slug: %r{[^/.]+}} do
    member do
      put :publish
      put "lock-signups", action: :lock_signups
      put "unlock-signups", action: :unlock_signups
      put :start
      put :complete
      put :cancel
      put :unarchive
      post "sync-to-discord", action: :sync_to_discord
      post :signup, to: "fleet_event_signups#event_signup"
      get "event.ics", action: :ics, defaults: {format: "ics"}, constraints: {format: "ics"}
    end

    resources :fleet_event_admins, path: "admins", only: %i[index create destroy]

    resources :fleet_event_teams, path: "teams", only: %i[create update destroy] do
      put :sort, on: :collection
      resources :fleet_event_ships, path: "ships", only: %i[create update destroy] do
        put :sort, on: :collection
        post "expand-from-model", action: :expand_from_model, on: :member
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
