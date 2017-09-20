# encoding: utf-8
# frozen_string_literal: true

module Queries
  Users = GraphQL::ObjectType.define do
    field :currentUser do
      type Types::UserType
      description 'The Current User'
      resolve ->(_obj, _args, ctx) { ctx[:current_user] }
    end
  end
end
