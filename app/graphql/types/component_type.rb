# encoding: utf-8
# frozen_string_literal: true

Types::ComponentType = GraphQL::ObjectType.define do
  name 'Component'

  field :id, !types.String
  field :name, types.String
  field :size, types.String
  field :type, types.String, property: :component_type
  field :createdAt, !types.String, property: :created_at
  field :updatedAt, !types.String, property: :updated_at
end
