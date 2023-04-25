# frozen_string_literal: true

namespace :short, path: "", host: Rails.configuration.app.short_domain do
  get "h/:username" => "base#hangar", :as => :public_hangar
  get "h/:username/wishlist" => "base#wishlist", :as => :public_wishlist
  get "fi/:token" => "base#fleet_invite", :as => :fleet_invite
  get "tr" => "base#trade_routes", :as => :trade_routes
  get "sc" => "base#model_compare", :as => :model_compare
end
