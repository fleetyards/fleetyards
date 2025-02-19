# frozen_string_literal: true

frontend_options = {
  path: "",
  host: Rails.configuration.app.domain,
  constraints: ->(req) { req.subdomain.blank? || %w[admin api docs].exclude?(req.subdomain) }
}.compact

namespace :frontend, **frontend_options do
  get "ships/mercury", to: redirect("/ships/mercury-star-runner")
  get "ships/compare", to: redirect("/compare/")
  get "compare/ships", to: redirect("/compare/")

  get "ships/:slug", to: "base#model", as: :model
  get "ships/:slug/images", to: "base#model_images", as: :model_images
  get "ships/:slug/videos", to: "base#model_videos", as: :model_videos

  get "hangar/:username", to: "hangar#index", as: :public_hangar
  get "hangar/:username/fleetchart", to: "hangar#index"
  get "hangar/:username/wishlist", to: "hangar#wishlist", as: :public_wishlist

  get "compare/ships", to: "base#compare_models"

  get "fleets/invites/:token", to: "fleets#invite", as: :fleet_invite
  get "fleets/:slug:", to: "fleets#show", as: :fleet
  get "fleets/:slug/ships", to: "fleets#show"
  get "fleets/:slug/fleetchart", to: "fleets#show"
  get "fleets/:slug/members", to: "fleets#members", as: :fleet_members
  get "fleets/:slug/stats", to: "fleets#stats"
  get "fleets/:slug/settings", to: "fleets#settings"
  get "fleets/:slug/settings/fleet", to: "fleets#settings"
  get "fleets/:slug/settings/membership", to: "fleets#settings"

  get "password/update/:token", to: "base#password", as: :password_reset
  get "confirm/:token", to: "base#confirm", as: :confirm

  get "embed", to: "embed#index"
  get "embed-v2", to: "embed#index_v2"
  get "embed-test", to: "embed#test"
  get "embed-v2-test", to: "embed#test_v2"
  get "embed-v2-username-test", to: "embed#test_v2_username"
  get "embed-v2-fleet-test", to: "embed#test_v2_fleet"

  get "settings/notifications", to: "base#index"
  get "settings/security", to: "base#index"

  get "privacy-policy", to: "base#index"

  get "manifest-:digest", to: "base#manifest", as: :manifest

  match "404", to: "base#not_found", via: :all

  root to: "base#index"
end

Rails.application.routes.append do
  namespace :frontend, **frontend_options do
    match "*path", to: "base#index", via: :all
  end
end
