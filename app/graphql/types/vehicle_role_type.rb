# encoding: utf-8
# frozen_string_literal: true

Types::VehicleRoleType = GraphQL::ObjectType.define do
  name 'VehicleRole'

  field :name, types.String
  field :slug, types.String
end
