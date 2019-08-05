# frozen_string_literal: true

namespace :admin, path: (ENV['ON_SUBDOMAIN'] ? 'admin' : ''), constraints: ->(req) { ENV['ON_SUBDOMAIN'] || req.subdomain == 'admin' } do
  draw :admin_api_routes

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
      get 'images'
      put 'reload_one'
    end
  end

  resources :model_modules, path: 'model-modules', except: [:show]
  resources :model_upgrades, path: 'model-upgrades', except: [:show]

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

  get 'quick-stats' => 'base#quick_stats'

  resource :stats, only: [] do
    get 'quick-stats' => 'stats#quick_stats'
    get 'most-viewed-pages' => 'stats#most_viewed_pages'
    get 'visits-per-day' => 'stats#visits_per_day'
    get 'visits-per-month' => 'stats#visits_per_month'
    get 'registrations-per-month' => 'stats#registrations_per_month'
  end

  root to: 'base#index'
end
