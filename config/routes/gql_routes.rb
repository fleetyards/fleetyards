# encoding: utf-8
# frozen_string_literal: true

namespace :gql, path: "", constraints: { subdomain: "gql" } do
  devise_for :users, only: []

  draw :gql_v1_routes

  root to: "base#root"
end
