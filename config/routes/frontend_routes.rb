# frozen_string_literal: true

namespace :frontend, path: '', constraints: { subdomain: 'stage' } do
  get 'embed' => 'base#embed'

  resources :ships, param: :slug, only: %i[index show]
  resources :fleets, param: :sid, only: %i[index show]

  get 'hangar' => 'hangar#show'
  get 'hangar/:username' => 'hangar#public'

  get 'cargo' => 'base#cargo'
  get 'commodities' => 'base#commodities'
  get 'images' => 'base#images'
  get 'impressum' => 'base#impressum'
  get 'privacy-policy' => 'base#privacy'
  get 'sign-up' => 'base#signup'
  get 'login' => 'base#login'
  get 'password/request' => 'base#password_request'

  get '/*path', to: 'base#index', format: false

  root to: 'base#home'
end
