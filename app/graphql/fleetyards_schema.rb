# frozen_string_literal: true

FleetyardsSchema = GraphQL::Schema.define do
  mutation(MutationType)
  query(QueryType)

  max_depth 3
end
