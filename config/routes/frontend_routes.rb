# frozen_string_literal: true

namespace :frontend, path: '', constraints: ->(req) { req.subdomain.blank? || !%w[admin api].include?(req.subdomain) } do
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

  get 'stations' => 'base#index'
  get 'shops' => 'base#index'
  get 'stations/:slug' => 'base#station'
  get 'stations/:station_slug/shops/:slug' => 'base#shop'
  get 'starsystems' => 'base#index'
  get 'starsystems/:slug' => 'base#starsystem'
  get 'celestial-objects/:slug' => 'base#celestial_object'

  get 'commodities' => 'base#index'
  get 'commodities/:id' => 'base#commodities'

  get 'images' => 'base#index'

  get 'stats' => 'base#index'

  get 'roadmap' => 'base#index'
  get 'roadmap/changes' => 'base#index'
  get 'roadmap/releases' => 'base#index'

  get 'impressum' => 'base#index'
  get 'privacy-policy' => 'base#index'
  get 'cookie-policy' => 'base#index'

  get 'sign-up' => 'base#index'
  get 'login' => 'base#index'

  get 'settings' => 'base#index'
  get 'settings/profile' => 'base#index'
  get 'settings/account' => 'base#index'
  get 'settings/change-password' => 'base#index'
  get 'settings/verify' => 'base#index'
  get 'settings/hangar' => 'base#index'

  get 'password/request' => 'base#index'
  get 'password/update/:token' => 'base#password'
  get 'confirm/:token' => 'base#confirm'

  get 'embed' => 'base#embed'
  get 'embed-v2' => 'base#embed_v2'
  get 'embed-test' => 'base#embed_test'
  get 'embed-v2-test' => 'base#embed_v2_test'

  get 'precache-manifest.:id' => 'base#precache_manifest'
  get 'service-worker' => 'base#service_worker'

  match '404' => 'base#not_found', via: :all

  root to: 'base#index'
end
