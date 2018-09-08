# frozen_string_literal: true

namespace :frontend, path: '', constraints: { subdomain: 'www' } do
  get 'ships/mercury', to: redirect('/ships/mercury-star-runner')

  get 'ships' => 'base#index'
  get 'ships/:slug' => 'base#model'
  get 'ships/:slug/images' => 'base#model_images'
  get 'ships/:slug/videos' => 'base#model_videos'

  get 'fleets' => 'base#index'
  get 'fleets/:sid' => 'base#fleet'

  get 'hangar' => 'base#index'
  get 'hangar/:username' => 'base#hangar'

  get 'compare/ships' => 'base#compare_models'

  get 'cargo' => 'base#index'

  get 'commodities' => 'base#index'
  get 'commodities/:id' => 'base#commodities'

  get 'images' => 'base#index'

  get 'impressum' => 'base#index'
  get 'privacy-policy' => 'base#index'

  get 'sign-up' => 'base#index'
  get 'login' => 'base#index'

  get 'settings' => 'base#index'
  get 'settings/profile' => 'base#index'
  get 'settings/account' => 'base#index'
  get 'settings/change-password' => 'base#index'
  get 'settings/verify' => 'base#index'

  get 'password/request' => 'base#index'
  get 'password/update/:token' => 'base#password'
  get 'confirm/:token' => 'base#confirm'

  get 'embed' => 'base#embed'
  get 'embed-styles' => 'base#embed_styles'
  get 'embed-test' => 'base#embed_test' if Rails.env.development?

  get 'service-worker' => 'base#service_worker'

  match '404' => 'base#not_found', via: :all

  root to: 'base#index'
end
