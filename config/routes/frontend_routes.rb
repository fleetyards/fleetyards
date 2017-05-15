# encoding: utf-8
# frozen_string_literal: true

constraints subdomain: "" do
  as :user do
    get 'register' => 'registrations#new', as: :new_registration
    post 'register' => 'registrations#create', as: :user_registration
    get 'users/edit' => 'registrations#edit', as: :edit_user_registration
    get 'users/cancel' => 'registrations#cancel', as: :cancel_user_registration
    get 'login' => 'sessions#new', as: :new_user_session
    post 'login' => 'sessions#create', as: :user_session
    delete 'logout' => 'sessions#destroy', as: :destroy_user_session
  end

  resource :password, only: %i[edit update]

  get 'impressum' => 'base#impressum'
  get 'privacy' => 'base#privacy'

  get '404' => 'errors#not_found'
  get '422' => 'errors#unprocessable_entity'
  get '500' => 'server_errors#server_error'

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

  resources :manufacturers, only: %i[index show], param: :slug

  # get ':username' => 'profile#show'
end
