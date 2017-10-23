# encoding: utf-8
# frozen_string_literal: true

Types::ClassificationCountType = GraphQL::ObjectType.define do
  name 'FleetClassificationCount'

  field :count, !types.Int
  field :name, !types.String
end
