# frozen_string_literal: true

resources :fleets, param: :slug, only: %i[show create update destroy] do
  collection do
    post :check
    get :invites
    get :current
    get :find_by_invite, path: 'check-invite/:token'
    post 'use-invite' => 'fleet_memberships#create_by_invite'
  end

  resources :fleet_vehicles, path: 'vehicles', only: [:index]

  resource :stats, only: %i[show] do
    get :members
    get :model_counts, path: 'model-counts'
    get 'stats/vehicles-by-model' => 'fleet_stats#vehicles_by_model'
    get 'stats/models-by-size' => 'fleet_stats#models_by_size'
    get 'stats/models-by-production-status' => 'fleet_stats#models_by_production_status'
    get 'stats/models-by-manufacturer' => 'fleet_stats#models_by_manufacturer'
    get 'stats/models-by-classification' => 'fleet_stats#models_by_classification'
  end

  resources :fleet_memberships, path: 'members', param: :username, only: %i[index create destroy] do
    collection do
      get :current
      put :update
      patch :update
      put 'accept-invite' => 'fleet_memberships#accept_invite'
      put 'decline-invite' => 'fleet_memberships#decline_invite'
      delete :leave
      post 'create-by-invite' => 'fleet_memberships#create_by_invite'
    end
    member do
      put :demote
      put :promote
      put 'accept-request' => 'fleet_memberships#accept_request'
      put 'decline-request' => 'fleet_memberships#decline_request'
    end
  end

  resources :fleet_invite_urls, path: 'invite-urls', param: :token, only: %i[index create destroy]

  namespace :public, path: 'public/:slug' do
    resources :fleet_vehicles, path: 'vehicles', only: %(index) do
      collection do
        get :embed
      end
    end

    resource :stats, only: %i[show] do
      get :model_counts, path: 'model-counts'
    end
  end
end
