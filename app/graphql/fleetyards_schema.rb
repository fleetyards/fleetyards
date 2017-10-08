# encoding: utf-8
# frozen_string_literal: true

FleetyardsSchema = GraphQL::Schema.define do
  mutation(MutationType)
  query(QueryType)

  max_depth 4
end
