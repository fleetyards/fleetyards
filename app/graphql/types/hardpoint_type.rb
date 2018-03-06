# frozen_string_literal: true

Types::HardpointType = GraphQL::ObjectType.define do
  name 'Hardpoint'

  field :id, types.String
  field :type, types.String, property: :hardpoint_type
  field :class, types.String, property: :component_class
  field :size, types.String
  field :quantity, types.String
  field :mounts, types.String
  field :details, types.String
  field :category, types.String
  field :defaultEmpty, types.String, property: :default_empty
  field :component, Types::ComponentType
end
