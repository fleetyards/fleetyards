# frozen_string_literal: true

namespace :short, path: "", host: Rails.configuration.app.short_domain do
  get "h/:username", to: "base#hangar", as: :public_hangar
  get "h/:username/wishlist", to: "base#wishlist", as: :public_wishlist
  get "fi/:token", to: "base#fleet_invite", as: :fleet_invite
  get "tr", to: "base#trade_routes", as: :trade_routes
  get "sc", to: "base#model_compare", as: :model_compare
end
