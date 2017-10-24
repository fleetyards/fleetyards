# encoding: utf-8
# frozen_string_literal: true

module Queries
  Fleets = GraphQL::ObjectType.define do
    field :myFleets do
      type types[!Types::FleetType]
      description 'My Fleets'
      needs_authentication true
      argument :limit, types.Int, default_value: 30, prepare: ->(limit, _ctx) { [limit, 100].min }
      argument :offset, types.Int, default_value: 0
      resolve Resolvers::Fleets::MyList.new
    end
    field :fleets do
      type types[!Types::FleetType]
      description 'Fleets'
      argument :limit, types.Int, default_value: 30, prepare: ->(limit, _ctx) { [limit, 100].min }
      argument :offset, types.Int, default_value: 0
      resolve Resolvers::Fleets::List.new
    end
    field :fleetModels do
      type types[!Types::FleetModelType]
      description 'Fleet'
      argument :sid, !types.String
      argument :q, InputTypes::ModelSearchType
      argument :limit, types.Int, default_value: 30, prepare: ->(limit, _ctx) { [limit, 100].min }
      argument :offset, types.Int, default_value: 0
      needs_authentication true
      resolve Resolvers::Fleets::Models.new
    end
    field :fleet do
      type !Types::FleetType
      description 'Fleet'
      argument :sid, !types.String
      resolve Resolvers::Fleets::Detail.new
    end
    field :fleetMembers do
      type types[!Types::FleetMemberType]
      description 'Fleet Members'
      argument :sid, !types.String
      needs_authentication true
      resolve Resolvers::Fleets::Members.new
    end
    field :fleetCount do
      type !Types::VehicleCountType
      description 'Fleet Count'
      argument :sid, !types.String
      needs_authentication true
      resolve Resolvers::Fleets::Count.new
    end
  end
end
