# frozen_string_literal: true

Types::FilterType = GraphQL::ObjectType.define do
  name 'Filter'

  field :category, types.String
  field :name, types.String
  field :value, types.String
  field :icon, types.String
end
