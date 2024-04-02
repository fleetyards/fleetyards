# frozen_string_literal: true

frontend_options = {
  path: "",
  host: Rails.configuration.app.domain,
  constraints: ->(req) { req.subdomain.blank? || %w[admin api docs].exclude?(req.subdomain) }
}.compact

namespace :frontend, **frontend_options do
  get "ships/mercury", to: redirect("/ships/mercury-star-runner")
  get "ships/compare", to: redirect("/compare/ships")

  get "search" => "base#index"

  get "ships" => "base#index", :as => :models
  get "ships/:slug" => "base#model", :as => :model
  get "ships/:slug/images" => "base#model_images", :as => :model_images
  get "ships/:slug/videos" => "base#model_videos", :as => :model_videos

  get "hangar" => "base#index"
  get "hangar/wishlist" => "base#index"
  get "hangar/preview" => "base#index"
  get "hangar/import" => "base#index"
  get "hangar/stats" => "base#index"
  get "hangar/:username" => "hangar#index", :as => :public_hangar
  get "hangar/:username/fleetchart" => "hangar#index"
  get "hangar/:username/wishlist" => "hangar#wishlist", :as => :public_wishlist

  get "compare/ships" => "base#compare_models"

  get "tools" => "base#index"
  get "tools/travel-times" => "base#index"

  get "commodities" => "base#index"
  get "commodities/:id" => "base#commodities"

  get "images" => "base#index"

  get "fleets" => "base#index"
  get "fleets/add" => "base#index"
  get "fleets/invites" => "base#index"
  get "fleets/invites/:token" => "fleets#invite", :as => :fleet_invite
  get "fleets/:slug" => "fleets#show", :as => :fleet
  get "fleets/:slug/ships" => "fleets#show"
  get "fleets/:slug/fleetchart" => "fleets#show"
  get "fleets/:slug/members" => "fleets#members", :as => :fleet_members
  get "fleets/:slug/stats" => "fleets#stats"
  get "fleets/:slug/settings" => "fleets#settings"
  get "fleets/:slug/settings/fleet" => "fleets#settings"
  get "fleets/:slug/settings/membership" => "fleets#settings"

  get "stats" => "base#index"

  get "roadmap" => "base#index", :as => :roadmap
  get "roadmap/changes" => "base#index", :as => :roadmap_changes
  get "roadmap/ships" => "base#index", :as => :roadmap_ships

  get "impressum" => "base#index"
  get "privacy-policy" => "base#index"

  get "sign-up" => "base#index"
  get "login" => "base#index"

  get "settings" => "base#index"
  get "settings/profile" => "base#index"
  get "settings/account" => "base#index"
  get "settings/change-password" => "base#index"
  get "settings/hangar" => "base#index"
  get "settings/notifications" => "base#index"
  get "settings/security" => "base#index"
  get "settings/security/two-factor/enable" => "base#index"
  get "settings/security/two-factor/disable" => "base#index"
  get "settings/security/two-factor/backup-codes" => "base#index"

  get "password/request" => "base#index"
  get "password/update/:token" => "base#password", :as => :password_reset
  get "confirm/:token" => "base#confirm", :as => :confirm

  get "embed" => "embed#index"
  get "embed-v2" => "embed#index_v2"
  get "embed-test" => "embed#test"
  get "embed-v2-test" => "embed#test_v2"
  get "embed-v2-username-test" => "embed#test_v2_username"
  get "embed-v2-fleet-test" => "embed#test_v2_fleet"

  get "visual-tests" => "base#index"
  get "visual-tests/:subroute" => "base#index"

  match "404" => "base#not_found", :via => :all

  root to: "base#index"
end
