# encoding: utf-8
# frozen_string_literal: true

Types::VehicleCountType = GraphQL::ObjectType.define do
  name 'VehicleCount'

  field :total, !types.Int
  field :classifications, types[!Types::ClassificationCountType]
end
