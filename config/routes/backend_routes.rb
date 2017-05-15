# encoding: utf-8
# frozen_string_literal: true

namespace :backend, constraints: { subdomain: "" } do
  put '/locales/fetch' => 'locales#fetch', as: :update_locales

  resources :users, except: [:show]

  resources :settings, except: %i[index show]

  authenticate :user, (->(u) { u.admin? }) do
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

  resources :images, only: %i[new index new create destroy] do
    put 'toggle', on: :member
  end

  get 'worker/:name/check' => 'worker#check_state', as: :check_worker_state

  root 'base#index'
end
