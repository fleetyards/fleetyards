# encoding: utf-8
# frozen_string_literal: true

namespace :admin, path: "", constraints: { subdomain: "admin" } do
  devise_for :users, skip: %i[registration]

  resource :password, only: %i[edit update]

  put '/locales/fetch' => 'locales#fetch', as: :update_locales

  resources :users, except: [:show]
  resources :user_ships, only: [:index]

  resources :settings, except: %i[index show]

  authenticate :admin_user, (->(u) { u.admin? }) do
    mount Sidekiq::Web => '/workers'
  end

  resources :ships, except: [:show] do
    put 'reload', on: :collection
    member do
      get 'gallery'
      put 'reload_one'
      put 'toggle'
    end
  end

  resources :manufacturers, except: [:show] do
    put 'toggle', on: :member
  end

  resources :components, except: [:show] do
    put 'toggle', on: :member
  end

  resources :images, except: %i[show new edit update] do
    put 'toggle', on: :member
  end

  get 'worker/:name/check' => 'worker#check_state', as: :check_worker_state

  root to: 'base#index'
end
