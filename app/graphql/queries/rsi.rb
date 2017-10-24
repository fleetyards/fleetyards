# encoding: utf-8
# frozen_string_literal: true

module Queries
  Rsi = GraphQL::ObjectType.define do
    field :citizen do
      type Types::CitizenType
      description 'RSI Citizen fetched by handle'
      argument :handle, !types.String
      resolve Resolvers::Citizen.new
    end
    field :org do
      type Types::OrgType
      description 'RSI Org fetched by sid'
      argument :sid, !types.String
      resolve Resolvers::Org.new
    end
  end
end
