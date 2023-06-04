# frozen_string_literal: true

namespace :admin, path: (Rails.configuration.app.on_subdomain? ? "" : "admin"), constraints: ->(req) { !Rails.configuration.app.on_subdomain? || req.subdomain == "admin" } do
  draw :admin_api_routes

  devise_for :admin_users,
    singular: :admin_user, path: "", skip: %i[registration],
    path_names: {
      sign_in: "login",
      sign_out: "logout"
    }

  resource :me, controller: :current_user, only: [] do
    get :otp
    get :otp_qrcode
    post :otp_backup_codes
    post :enable_otp
    post :disable_otp
  end

  resource :password, only: %i[edit update]

  resources :users, except: [:show] do
    member do
      post "login-as" => "users#login_as", :as => :login_as
      put "resend-confirmation" => "users#resend_confirmation", :as => :resend_confirmation
    end
  end

  resources :admin_users, except: [:show] do
    member do
      put "resend-confirmation" => "admin_users#resend_confirmation", :as => :resend_confirmation
    end
  end

  resources :vehicles, only: [:index]

  resources :settings, except: %i[index show]

  authenticate :admin_user, (->(u) { u.present? }) do
    mount Sidekiq::Web => "/workers"
    mount PgHero::Engine => "/pghero"
    mount Flipper::UI.app(Flipper) => "/features", :as => :features
  end

  resources :models, except: [:show] do
    collection do
      get :name_diff
      get :price_diff
      put "reload"
      put "reload_data"
      resources :loaner_uploads, only: %i[new create]
    end

    member do
      get "images"
      put "reload_one"
      put "use_rsi_image"
    end
  end

  resources :model_modules, path: "model-modules", except: [:show]
  resources :model_module_packages, path: "model-module-packages", except: [:show]
  resources :model_upgrades, path: "model-upgrades", except: [:show]
  resources :model_paints, path: "model-paints", except: [:show] do
    collection do
      put :import
    end
  end

  resources :manufacturers, except: [:show]

  resources :components, except: [:show]

  resources :images, only: %i[index]

  resources :celestial_objects, path: "celestial-objects", except: [:show]
  resources :starsystems, except: [:show]
  resources :commodities, except: [:show]
  resources :equipment, except: [:show]
  resources :stations, except: [:show] do
    get "images", on: :member
  end
  resources :shops, except: [:show] do
    resources :shop_commodities, path: "commodities", only: %i[index]
  end

  resources :shop_commodities, path: "shop-commodities", only: %i[] do
    collection do
      get :confirmation
    end
  end

  resources :commodity_prices, path: "commodity-prices", only: %i[] do
    collection do
      get :confirmation
    end
  end

  resource :maintenance, only: [] do
    get "rsi-api-status" => "maintenance#rsi_api_status", :as => :rsi_api_status
  end

  get "worker/:name/check" => "worker#check_state", :as => :check_worker_state

  root to: "base#index"
end
