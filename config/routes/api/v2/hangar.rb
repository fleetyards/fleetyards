# frozen_string_literal: true

namespace :hangar do
  resources :vehicles do
    collection do
      get :export
      put :import
      post :check_serial, path: "check-serial"
      put :update_bulk, path: "bulk"
      put :destroy_bulk, path: "destroy-bulk"
      delete :destroy_all, path: "destroy-all"
    end
  end

  resources :groups, only: %i[index create update destroy] do
    collection do
      put :sort
    end
  end

  resource :stats, only: %i[show] do
    get :models_by_size, path: "models-by-size"
    get :models_by_production_status, path: "models-by-production-status"
    get :models_by_manufacturer, path: "models-by-manufacturer"
    get :models_by_classification, path: "models-by-classification"
  end

  namespace :public, path: "public/:username" do
    resources :vehicles, only: %(index) do
      collection do
        get :embed
      end
    end

    resources :groups, only: %i[index]

    resource :stats, only: %i[show]
  end
end
