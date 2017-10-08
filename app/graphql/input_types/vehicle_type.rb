# frozen_string_literal: true

InputTypes::VehicleType = ::GraphQL::InputObjectType.define do
  name 'VehicleInput'

  argument :name, types.String
  argument :purchased, types.Boolean
  argument :saleNotify, types.Boolean, as: :sale_notify
end
