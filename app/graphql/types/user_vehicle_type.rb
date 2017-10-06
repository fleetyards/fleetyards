# encoding: utf-8
# frozen_string_literal: true

Types::UserVehicleType = GraphQL::ObjectType.define do
  name 'UserVehicle'

  field :id, types.String
  field :name, types.String
  field :purchased, types.Boolean
  field :saleNotify, types.Boolean, property: :sale_notify
  field :vehicle, Types::VehicleType, property: :ship
end
