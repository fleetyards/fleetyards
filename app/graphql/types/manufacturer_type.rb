# encoding: utf-8
# frozen_string_literal: true

Types::ManufacturerType = GraphQL::ObjectType.define do
  name 'Manufacturer'

  field :name, !types.String
  field :slug, !types.String
  field :logo, types.String do
    resolve ->(obj, _args, _ctx) { obj.logo.small.url }
  end
  field :models, types[Types::ModelType], property: :ships
end
