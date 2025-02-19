# frozen_string_literal: true

admin_options = {
  path: (Rails.configuration.app.on_subdomain? ? "" : "admin"),
  constraints: ->(req) { !Rails.configuration.app.on_subdomain? || req.subdomain == "admin" }
}.compact

namespace :admin, **admin_options do
  draw "admin/api_routes"

  authenticate :admin_user, ->(u) { u.present? && u.access_to?(:workers) } do
    mount Sidekiq::Web => "/workers"
  end
  authenticate :admin_user, ->(u) { u.present? && u.access_to?(:pghero) } do
    mount PgHero::Engine => "/pghero"
  end
  authenticate :admin_user, ->(u) { u.present? && u.access_to?(:features) } do
    mount Flipper::UI.app(Flipper) => "/features", :as => :features
  end

  # devise_for :admin_users,
  #   singular: :admin_user, path: "", skip: %i[registration],
  #   path_names: {
  #     sign_in: "login",
  #     sign_out: "logout"
  #   }

  # resource :me, controller: :current_user, only: [] do
  #   get :otp
  #   get :otp_qrcode
  #   post :otp_backup_codes
  #   post :enable_otp
  #   post :disable_otp
  # end

  # resource :password, only: %i[edit update]

  # resources :users, except: [:show] do
  #   member do
  #     post "login-as" => "users#login_as", :as => :login_as
  #     put "resend-confirmation" => "users#resend_confirmation", :as => :resend_confirmation
  #   end
  # end

  # resources :admin_users, except: [:show] do
  #   member do
  #     put "resend-confirmation" => "admin_users#resend_confirmation", :as => :resend_confirmation
  #   end
  # end

  # resources :vehicles, only: [:index]

  # resources :settings, except: %i[index show]

  # resources :manufacturers, except: [:show]

  # resources :images, only: %i[index]

  # resource :maintenance, only: [] do
  #   get "rsi-api-status" => "maintenance#rsi_api_status", :as => :rsi_api_status
  # end

  get "models/paints", to: "base#index"
  get "models/modules", to: "base#index"
  get "models/:id", to: "base#model", as: :model
  get "models/:id/edit", to: "base#model", as: :model_edit
  get "models/:id/images", to: "base#model", as: :model_images
  get "models/:id/videos", to: "base#model", as: :model_videos

  get "worker/:name/check", to: "worker#check_state", as: :check_worker_state

  get "manifest-:digest", to: "base#manifest", as: :manifest

  root to: "base#index"
end

Rails.application.routes.append do
  namespace :admin, **admin_options do
    match "*path", to: "base#index", via: :all
  end
end
