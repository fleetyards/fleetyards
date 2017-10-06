# encoding: utf-8
# frozen_string_literal: true

module Queries
  Images = GraphQL::ObjectType.define do
    field :images do
      type types[!Types::ImageType]
      description 'All Images'
      argument :vehicleSlug, types.String, as: :vehicle_slug
      argument :random, types.Boolean, default_value: false
      argument :limit, types.Int, default_value: 50, prepare: ->(limit, _ctx) { [limit, 100].min }
      argument :offset, types.Int, default_value: 0
      resolve Resolvers::Images.new
    end
  end
end
