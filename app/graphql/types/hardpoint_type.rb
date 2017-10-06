# encoding: utf-8
# frozen_string_literal: true

Types::HardpointType = GraphQL::ObjectType.define do
  name 'Hardpoint'

  field :id, !types.String
  field :name, types.String
  field :class, types.String, property: :hardpoint_class
  field :rating, types.String
  field :maxSize, types.String, property: :max_size
  field :quantity, types.String
  field :category, Types::ComponentCategoryType
  field :component, Types::ComponentType
  field :createdAt, !types.String, property: :created_at
  field :updatedAt, !types.String, property: :updated_at
end
