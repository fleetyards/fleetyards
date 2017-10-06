# encoding: utf-8
# frozen_string_literal: true

module Queries
  Hangar = GraphQL::ObjectType.define do
    field :hangar do
      type types[!Types::UserVehicleType]
      description 'Your Hangar Vehicles'
      needs_authentication true
      argument :q, InputTypes::UserVehicleSearchType
      argument :limit, types.Int, default_value: 30, prepare: ->(limit, _ctx) { [limit, 100].min }
      argument :offset, types.Int, default_value: 0
      resolve Resolvers::Hangar.new
    end

    field :hangarCount do
      type types.Int
      description 'Your Hangar Vehicles Count'
      needs_authentication true
      resolve Resolvers::HangarCount.new
    end

    field :publicHangar do
      type types[!Types::UserVehicleType]
      description 'Hangar Vehicles for User'
      argument :username, !types.String
      argument :q, InputTypes::UserVehicleSearchType
      argument :limit, types.Int, default_value: 30, prepare: ->(limit, _ctx) { [limit, 100].min }
      argument :offset, types.Int, default_value: 0
      resolve Resolvers::Hangar.new
    end

    field :publicHangarCount do
      type types.Int
      description 'Hangar Vehicles Count for User'
      argument :username, !types.String
      resolve Resolvers::HangarCount.new
    end
  end
end
