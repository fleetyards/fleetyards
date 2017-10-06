# encoding: utf-8
# frozen_string_literal: true

module Queries
  Components = GraphQL::ObjectType.define do
    field :components do
      type types[!Types::ComponentType]
      description 'All Components'
      argument :limit, types.Int, default_value: 30, prepare: ->(limit, _ctx) { [limit, 100].min }
      argument :offset, types.Int, default_value: 0
      resolve Resolvers::Components.new
    end

    field :componentCategories do
      type types[!Types::ComponentCategoryType]
      description 'All Component Caregories'
      resolve Resolvers::ComponentCategories.new
    end
  end
end
