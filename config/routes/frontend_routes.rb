# frozen_string_literal: true

namespace :frontend, path: '', constraints: ->(req) { req.subdomain.blank? || !%w[admin api].include?(req.subdomain) } do
  get 'ships/mercury', to: redirect('/ships/mercury-star-runner')
  get 'compare/ships', to: redirect('/ships/compare')

  get 'search' => 'base#index'

  get 'ships' => 'base#index'
  get 'ships/:slug' => 'base#model'
  get 'ships/:slug/images' => 'base#model_images'
  get 'ships/:slug/videos' => 'base#model_videos'

  get 'hangar' => 'base#index'
  get 'hangar/preview' => 'base#index'
  get 'hangar/import' => 'base#index'
  get 'hangar/stats' => 'base#index'
  get 'hangar/:username' => 'hangar#index'

  get 'compare/ships' => 'base#compare_models'

  get 'trade-routes' => 'base#index'

  get 'stations' => 'base#index'
  get 'shops' => 'base#index'
  get 'stations/:slug' => 'base#station'
  get 'stations/:slug/images' => 'base#station_images'
  get 'stations/:station_slug/shops/:slug' => 'base#shop'
  get 'starsystems' => 'base#index'
  get 'starsystems/:slug' => 'base#starsystem'
  get 'celestial-objects/:slug' => 'base#celestial_object'

  get 'commodities' => 'base#index'
  get 'commodities/:id' => 'base#commodities'

  get 'images' => 'base#index'

  get 'fleets' => 'base#index'
  get 'fleets/add' => 'base#index'
  get 'fleets/invites' => 'base#index'
  get 'fleets/:slug' => 'fleets#show'
  get 'fleets/:slug/members' => 'fleets#members'
  get 'fleets/:slug/settings' => 'fleets#settings'

  get 'stats' => 'base#index'

  get 'roadmap' => 'base#index'
  get 'roadmap/changes' => 'base#index'
  get 'roadmap/ships' => 'base#index'

  get 'impressum' => 'base#index'
  get 'privacy-policy' => 'base#index'
  get 'cookie-policy' => 'base#index'

  get 'sign-up' => 'base#index'
  get 'login' => 'base#index'

  get 'settings' => 'base#index'
  get 'settings/profile' => 'base#index'
  get 'settings/account' => 'base#index'
  get 'settings/change-password' => 'base#index'
  get 'settings/hangar' => 'base#index'

  get 'password/request' => 'base#index'
  get 'password/update/:token' => 'base#password', as: :password_reset
  get 'confirm/:token' => 'base#confirm', as: :confirm

  get 'embed' => 'embed#index'
  get 'embed-v2' => 'embed#index_v2'
  get 'embed-test' => 'embed#test'
  get 'embed-v2-test' => 'embed#test_v2'
  get 'embed-v2-username-test' => 'embed#test_v2_username'

  get 'service-worker' => 'service_worker#index'
  get 'precache-manifest.:id' => 'service_worker#precache_manifest'

  match '404' => 'base#not_found', via: :all

  root to: 'base#index'
end
