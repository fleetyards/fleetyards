# encoding: utf-8
# frozen_string_literal: true

Types::ManufacturerType = GraphQL::ObjectType.define do
  name 'Manufacturer'

  field :name, !types.String
  field :slug, !types.String
  field :vehicles, types[Types::VehicleType], property: :ships
end
