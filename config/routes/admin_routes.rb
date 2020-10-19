# frozen_string_literal: true

namespace :admin, path: (ENV['ON_SUBDOMAIN'] ? 'admin' : ''), constraints: ->(req) { ENV['ON_SUBDOMAIN'] || req.subdomain == 'admin' } do
  draw :admin_api_routes

  devise_for :admin_users,
             singular: :admin_user, path: '', skip: %i[registration],
             path_names: {
               sign_in: 'login',
               sign_out: 'logout',
             }

  resource :password, only: %i[edit update]

  resources :users, except: [:show] do
    member do
      put 'resend-confirmation' => 'users#resend_confirmation', as: :resend_confirmation
    end
  end

  resources :admin_users, except: [:show] do
    member do
      put 'resend-confirmation' => 'admin_users#resend_confirmation', as: :resend_confirmation
    end
  end

  resources :vehicles, only: [:index]

  resources :settings, except: %i[index show]

  authenticate :admin_user, (->(u) { u.present? }) do
    mount Sidekiq::Web => '/workers'
  end

  resources :models, except: [:show] do
    put 'reload', on: :collection
    member do
      get 'images'
      put 'reload_one'
      put 'use_rsi_image'
    end
  end

  resources :model_modules, path: 'model-modules', except: [:show]
  resources :model_upgrades, path: 'model-upgrades', except: [:show]
  resources :model_paints, path: 'model-paints', except: [:show]

  resources :manufacturers, except: [:show]

  resources :components, except: [:show]

  resources :images, only: %i[index]

  resources :celestial_objects, path: 'celestial-objects', except: [:show]
  resources :starsystems, except: [:show]
  resources :commodities, except: [:show]
  resources :equipment, except: [:show]
  resources :stations, except: [:show] do
    get 'images', on: :member
  end
  resources :shops, except: [:show]

  get 'worker/:name/check' => 'worker#check_state', as: :check_worker_state

  root to: 'base#index'
end
