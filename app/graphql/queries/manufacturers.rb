# encoding: utf-8
# frozen_string_literal: true

module Queries
  Manufacturers = GraphQL::ObjectType.define do
    field :manufacturers do
      type types[!Types::ManufacturerType]
      description 'All Manufacturers'
      argument :q, InputTypes::ManufacturerSearchType
      resolve(lambda do |_obj, args, _ctx|
        Manufacturer.enabled
                    .ransack(args[:q].to_h)
                    .result
                    .order(name: :asc)
      end)
    end

    field :manufacturer do
      type Types::ManufacturerType
      description 'Find a Manufacturer by Slug'
      argument :slug, !types.String
      resolve ->(_obj, args, _ctx) { Manufacturer.enabled.find_by(slug: args[:slug]) }
    end
  end
end
