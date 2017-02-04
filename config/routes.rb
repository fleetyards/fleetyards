# frozen_string_literal: true
require 'sidekiq/web'

Fleetyards::Application.routes.draw do
  concern :paginatable do
    get '(page/:page)', action: :index, on: :collection, as: ''
  end

  devise_for :users, skip: [:session, :password, :registration], controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  draw :api_routes

  scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do
    devise_for :users, skip: [:sessions, :omniauth_callbacks], controllers: {
      registrations: "registrations"
    }

    namespace :backend do
      put '/locales/fetch' => 'locales#fetch', as: :update_locales

      resources :users, except: [:show]

      resources :settings, except: [:index, :show]

      authenticate :user, ->(u) { u.admin? } do
        mount Sidekiq::Web => '/workers'
      end

      resources :ships do
        put 'reload', on: :collection
        member do
          get 'gallery'
          put 'reload_one'
          put 'toggle'
        end
      end

      resources :manufacturers do
        put 'toggle', on: :member
      end

      resources :components do
        put 'toggle', on: :member
      end

      resources :images, only: [:new, :index, :new, :create, :destroy] do
        put 'toggle', on: :member
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

    resources :ships, param: :slug, concerns: :paginatable do
      member do
        get 'gallery'
      end
    end

    resource :hangar, only: [:show] do
      collection do
        get ':username' => 'hangars#public', as: :public
      end
    end
    resources :my_ships, except: [:index], path_names: { new: 'add' }

    resources :images, only: [:index]

    resources :components, only: [:show] do
      collection do
        get :propulsion
        get :ordnance
        get :modular
        get :avionics
      end
    end

    resources :manufacturers, only: [:index, :show], param: :slug

    get 'impressum' => 'base#impressum'
    get 'privacy' => 'base#privacy'

    get '404' => 'errors#not_found'
    get '422' => 'errors#unprocessable_entity'
    get '500' => 'server_errors#server_error'

    # get ':username' => 'profile#show'

    root 'base#index'
  end

  # get '*path', to: redirect("/#{I18n.default_locale}/%{path}"), constraints: lambda { |req| !req.path.starts_with? "/#{I18n.default_locale}/" }
  get '', to: redirect("/#{I18n.default_locale}")
end
