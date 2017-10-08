# encoding: utf-8
# frozen_string_literal: true

v1_gql_routes = lambda do
  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/v1'
  end

  get "/docs", to: "base#docs"

  post "/", to: "base#execute"
end

scope :v1, as: :v1 do
  scope module: :v1, &v1_gql_routes

  root to: "v1/base#execute"
end
