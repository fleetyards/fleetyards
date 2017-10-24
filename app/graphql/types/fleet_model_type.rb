# encoding: utf-8
# frozen_string_literal: true

Types::FleetModelType = GraphQL::ObjectType.define do
  name 'FleetModel'

  field :count, !types.Int
  field :model, !Types::ModelType
end
