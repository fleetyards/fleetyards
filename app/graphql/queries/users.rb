# encoding: utf-8
# frozen_string_literal: true

module Queries
  Users = GraphQL::ObjectType.define do
    field :currentUser do
      type Types::UserType
      description 'The Current User'
      needs_authentication true
      resolve Resolvers::CurrentUser.new
    end
  end
end
