require 'resque/server'

Fleetyards::Application.routes.draw do
  mount RailsAssetLocalization::Engine => "/locales"

  scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do
    devise_for :users, skip: [:sessions], controllers: { registrations: "registrations" }

    namespace :backend do
      put '/locales/fetch' => 'locales#fetch', as: :update_locales

      resources :users, except: [:show]

      resources :settings, except: [:index, :show]

      authenticate :user, lambda {|u| u.admin? } do
        mount Resque::Server.new, :at => "/workers"
      end

      resources :ships, param: :slug do
        get 'gallery', on: :member
        put 'reload', on: :collection
      end

      resources :images, only: [:new, :index, :new, :create, :destroy] do
        collection do
          put 'enable'
          put 'disable'
        end
      end

      get 'worker/:name/check' => 'worker#check_state', as: :check_worker_state

      root 'base#index'
    end

    as :user do
      get 'register' => 'registrations#new', as: :new_registration
      get 'login' => 'sessions#new', as: :new_user_session
      post 'login' => 'sessions#create', as: :user_session
      delete 'logout' => 'sessions#destroy', as: :destroy_user_session
    end

    resource :password, only: [:edit, :update]

    resources :ships, param: :slug do
      get 'gallery', on: :member
    end

    resources :weapons, only: [:index, :show]

    resources :equipments, only: [:index, :show]

    resources :manufacturers, only: [:index], param: :slug

    # resources :ship_roles, param: :slug

    get 'impressum' => 'base#impressum'
    get 'privacy' => 'base#privacy'

    root 'base#index'
  end

  #get '*path', to: redirect("/#{I18n.default_locale}/%{path}"), constraints: lambda { |req| !req.path.starts_with? "/#{I18n.default_locale}/" }
  get '', to: redirect("/#{I18n.default_locale}")
end
