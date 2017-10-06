# encoding: utf-8
# frozen_string_literal: true

module Queries
  Rsi = GraphQL::ObjectType.define do
    field :orgs do
      type types[!Types::OrgType]
      description 'RSI Orgs in FleetYards'
      argument :limit, types.Int, default_value: 30, prepare: ->(limit, _ctx) { [limit, 100].min }
      argument :offset, types.Int, default_value: 0
      resolve Resolvers::Orgs.new
    end

    field :org do
      type Types::OrgType
      description 'RSI Org fetched by sid'
      argument :sid, !types.String
      resolve Resolvers::Orgs.new
    end

    field :orgShips do
      type types[!Types::UserVehicleType]
      description 'RSI Org Ships'
      argument :sid, !types.String
      argument :q, InputTypes::UserVehicleSearchType
      argument :limit, types.Int, default_value: 30, prepare: ->(limit, _ctx) { [limit, 100].min }
      argument :offset, types.Int, default_value: 0
      resolve Resolvers::OrgShips.new
    end

    field :citizen do
      type Types::CitizenType
      description 'RSI Citizen fetched by handle'
      argument :handle, !types.String
      resolve Resolvers::Citizen.new
    end
  end
end
