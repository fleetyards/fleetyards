# encoding: utf-8
# frozen_string_literal: true

module Mutations
  Sessions = GraphQL::ObjectType.define do
    field :createSession do
      type !Types::SessionType
      description 'Create new Session'
      argument :login, !types.String
      argument :password, !types.String
      resolve Resolvers::Sessions.new
    end
  end
end
