# frozen_string_literal: true

namespace :admin, path: '', constraints: { subdomain: 'admin' } do
  devise_for :users, skip: %i[registration]

  resource :password, only: %i[edit update]

  put '/locales/fetch' => 'locales#fetch', as: :update_locales

  resources :users, except: [:show]
  resources :vehicles, only: [:index]

  resources :settings, except: %i[index show]

  authenticate :admin_user, (->(u) { u.admin? }) do
    mount Sidekiq::Web => '/workers'
  end

  resources :models, except: [:show] do
    put 'reload', on: :collection
    member do
      get 'gallery'
      put 'reload_one'
    end
  end

  resources :manufacturers, except: [:show]

  resources :components, except: [:show]

  resources :images, except: %i[show new edit update] do
    put 'toggle', on: :member
    put 'toggle_background', on: :member
  end

  resources :trade_hubs, except: [:show]
  resources :commodities, except: [:show]
  resources :stations, except: [:show] do
    get 'gallery', on: :member
  end

  get 'worker/:name/check' => 'worker#check_state', as: :check_worker_state

  root to: 'base#index'
end
