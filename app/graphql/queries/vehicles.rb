# encoding: utf-8
# frozen_string_literal: true

module Queries
  Vehicles = GraphQL::ObjectType.define do
    field :vehicles do
      type types[!Types::VehicleType]
      description 'Your Hangar Vehicles'
      argument :q, InputTypes::VehicleSearchType
      argument :limit, types.Int, default_value: 30, prepare: ->(limit, _ctx) { [limit, 100].min }
      argument :offset, types.Int, default_value: 0
      needs_authentication true
      resolve Resolvers::Vehicles::List.new
    end

    field :publicVehicles do
      type types[!Types::VehicleType]
      description 'Public Hangar Vehicles'
      argument :username, types.String
      argument :q, InputTypes::VehicleSearchType
      argument :limit, types.Int, default_value: 30, prepare: ->(limit, _ctx) { [limit, 100].min }
      argument :offset, types.Int, default_value: 0
      resolve Resolvers::Vehicles::Public.new
    end

    field :vehiclesCount do
      type Types::VehicleCountType
      description 'Your Hangar Vehicles Count'
      needs_authentication true
      resolve Resolvers::Vehicles::Count.new
    end

    field :publicVehiclesCount do
      type Types::VehicleCountType
      description 'Public Hangar Vehicles Count'
      argument :username, types.String
      resolve Resolvers::Vehicles::PublicCount.new
    end
  end
end
