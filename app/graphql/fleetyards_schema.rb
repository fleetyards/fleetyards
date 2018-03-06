# frozen_string_literal: true

require 'graphql/batch'

FleetyardsSchema = GraphQL::Schema.define do
  # mutation(Types::MutationType)
  query(Types::QueryType)

  max_depth 5

  use GraphQL::Batch
end
