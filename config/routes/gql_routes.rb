# frozen_string_literal: true

namespace :gql, path: "", constraints: { subdomain: "gql" } do
  mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/'
  root to: 'base#execute', via: %i[post get]
end
