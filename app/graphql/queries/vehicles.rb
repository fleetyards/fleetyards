# encoding: utf-8
# frozen_string_literal: true

module Queries
  Vehicles = GraphQL::ObjectType.define do
    field :vehicles do
      type types[!Types::VehicleType]
      description 'All Vehicles'
      argument :q, InputTypes::VehicleSearchType
      argument :limit, types.Int, default_value: 30, prepare: ->(limit, _ctx) { [limit, 100].min }
      argument :offset, types.Int, default_value: 0
      resolve Resolvers::Vehicles.new
    end

    field :vehicle do
      type Types::VehicleType
      description 'Find a Vehicle by Slug'
      argument :slug, !types.String
      resolve Resolvers::Vehicles.new
    end
  end
end
