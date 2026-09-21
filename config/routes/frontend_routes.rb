# frozen_string_literal: true

frontend_options = {
  path: "",
  host: Rails.configuration.app.domain,
  constraints: ->(req) { req.subdomain.blank? || %w[admin api docs].exclude?(req.subdomain) }
}.compact

namespace :frontend, **frontend_options do
  get "ships/mercury", to: redirect("/ships/CRUS-mercury-star-runner")
  get "ships/compare", to: redirect("/compare/")
  get "compare/ships", to: redirect(status: 301) { |_params, req|
    req.query_string.empty? ? "/compare/" : "/compare/?#{req.query_string}"
  }

  # Meta tags for a shared link, the way a ship's page has them -- without this
  # the card renders the generic site description rather than the component.
  # No `og_image`: no component in the catalogue has one.
  get "catalogue/components/:slug", to: "base#component", as: :component

  # The path the page shipped under before the section existed. Live since
  # #5015, and every hardpoint on every ship linked to it, so it moves rather
  # than disappears.
  get "components/:slug", to: redirect("/catalogue/components/%{slug}", status: 301)
  get "components", to: redirect("/catalogue/components/", status: 301)

  # Meta tags for a shared link. Unlike components, a commodity can carry an
  # `og_image`: 63 of the 232 ship a store icon.
  #
  # No legacy redirect beside it -- there has never been a public `/commodities`
  # page for one to come from.
  get "catalogue/commodities/:slug", to: "base#commodity", as: :commodity

  get "ships/:slug", to: "base#model", as: :model
  get "ships/:slug/images", to: "base#model_images", as: :model_images
  get "ships/:slug/videos", to: "base#model_videos", as: :model_videos

  # Views that used to be paths of their own and are query state now. Every one
  # of them is live -- shared, bookmarked, and in the invite list's case in mail
  # that has already gone out -- so the server answers it, rather than letting
  # the app load and bounce.
  #
  # Declared above `hangar/:username`, which matches any single segment and
  # renders the app shell even for a username nobody has: below it,
  # `hangar/transactions` would answer 200 and never redirect.
  {
    "hangar/transactions" => ["tab=log", ->(_params) { "/hangar/inventories/" }],
    "hangar/transfers/outgoing" => ["direction=outgoing", ->(_params) { "/hangar/transfers/" }],
    "hangar/inventories/:inventory/transactions" =>
      ["tab=log", ->(params) { "/hangar/inventories/#{params[:inventory]}/" }],
    "hangar/:id/cargo/transactions" => ["tab=log", ->(params) { "/hangar/#{params[:id]}/cargo/" }],
    "fleets/:slug/members/invites" =>
      ["view=invites", ->(params) { "/fleets/#{params[:slug]}/members/" }],
    "fleets/:slug/logistics/transactions" =>
      ["tab=log", ->(params) { "/fleets/#{params[:slug]}/logistics/" }],
    "fleets/:slug/logistics/transfers/outgoing" =>
      ["direction=outgoing", ->(params) { "/fleets/#{params[:slug]}/logistics/transfers/" }],
    "fleets/:slug/logistics/inventories/:inventory/transactions" =>
      ["tab=log", ->(params) { "/fleets/#{params[:slug]}/logistics/inventories/#{params[:inventory]}/" }]
  }.each do |path, (state, target)|
    get path, to: redirect(status: 301) { |params, request|
      # The view the path names wins over one the link also carried: repeated
      # keys reach the client router as an array, and what reads them there
      # expects a single value -- so `?tab=stock` appended to the ledger's old
      # path would have opened the stock list that path was not asking for.
      #
      # Split rather than round-tripped through `to_query`, which renames a
      # repeated key to `roleIn[]` and loses every filter holding more than one
      # value.
      key = state.split("=").first
      carried = request.query_string.split("&").reject { |pair| pair.split("=", 2).first == key }

      "#{target.call(params)}?#{[state, *carried].join("&")}"
    }
  end

  get "hangar", to: "hangar#index", as: :hangar
  get "hangar/:username", to: "hangar#public", as: :public_hangar
  get "hangar/:username/fleetchart", to: "hangar#public"
  get "hangar/:username/stats", to: "hangar#public"
  get "hangar/:username/wishlist", to: "hangar#wishlist", as: :public_wishlist

  get "compare", to: "base#compare_models"

  get "fleets/invites", to: "base#index", as: :fleets_invites
  get "fleets/invites/:token", to: "fleets#invite", as: :fleet_invite
  get "fleets/:slug", to: "fleets#show", as: :fleet
  get "fleets/:slug/ships", to: "fleets#show"
  get "fleets/:slug/fleetchart", to: "fleets#show"
  get "fleets/:slug/members", to: "fleets#members", as: :fleet_members
  get "fleets/:slug/allies", to: "fleets#show", as: :fleet_allies
  get "fleets/:slug/allies/incoming", to: "fleets#show", as: :incoming_fleet_allies
  get "fleets/:slug/stats", to: "fleets#stats"
  get "fleets/:slug/settings", to: "fleets#settings"
  get "fleets/:slug/settings/fleet", to: "fleets#settings"
  get "fleets/:slug/settings/membership", to: "fleets#settings"
  get "fleets/:fleet_slug/events/:event_slug", to: "fleets#event", as: :fleet_event

  get "password/update/:token", to: "base#password", as: :password_reset
  get "confirm/:token", to: "base#confirm", as: :confirm

  get "embed", to: "embed#index"
  get "embed-v2", to: "embed#index_v2"
  get "embed-test", to: "embed#test"
  get "embed-v2-test", to: "embed#test_v2"
  get "embed-v2-username-test", to: "embed#test_v2_username"
  get "embed-v2-fleet-test", to: "embed#test_v2_fleet"

  get "notifications", to: "base#index", as: :notifications
  get "settings", to: "base#index", as: :settings_account
  get "settings/notifications", to: "base#index"
  get "settings/friends", to: "base#index", as: :friends
  # The list a request is answered on. A notification that dropped the reader on
  # the accepted friends is pointing at the one list the request is not in.
  get "settings/friends/incoming", to: "base#index", as: :incoming_friends
  get "settings/connections", to: "base#index", as: :connections_settings
  get "settings/security", to: "base#index", as: :security_settings

  get "privacy-policy", to: "base#index"

  get "manifest-:digest", to: "base#manifest", as: :manifest

  get "sign-up", to: "base#index", as: :sign_up

  get "login", to: "base#index", as: :login

  get "sign-up/auth-callback", to: "base#index", as: :sign_up_auth_callback

  root to: "base#index"
end

Rails.application.routes.append do
  namespace :frontend, **frontend_options do
    match "*path", to: "base#index", via: :all
  end
end
