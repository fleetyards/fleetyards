# encoding: utf-8
# frozen_string_literal: true

Types::VehicleType = GraphQL::ObjectType.define do
  name 'Vehicle'

  field :id, types.String
  field :name, types.String
  field :purchased, types.Boolean
  field :saleNotify, types.Boolean, property: :sale_notify
  field :model, Types::ModelType, property: :ship
end
