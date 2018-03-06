# frozen_string_literal: true

Types::ComponentType = GraphQL::ObjectType.define do
  name 'Component'

  field :id, types.String
  field :name, types.String
  field :slug, types.String
  field :size, types.String
  field :class, types.String, property: :component_class
  field :type, types.String, property: :component_type
  field :manufacturer, Types::ManufacturerType
end
