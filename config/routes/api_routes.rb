# frozen_string_literal: true

namespace :api, path: "", constraints: { subdomain: "api" } do
  devise_for :users, only: []

  draw :api_v1_routes

  root to: "base#root"
end
