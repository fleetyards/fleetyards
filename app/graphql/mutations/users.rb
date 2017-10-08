# encoding: utf-8
# frozen_string_literal: true

module Mutations
  Users = GraphQL::ObjectType.define do
    field :signup do
      type Types::UserType
      description 'Create new User'
      argument :data, !InputTypes::UserType
      resolve Resolvers::Users::Signup.new
    end
    field :confirm do
      type Types::ResultType
      description 'Confirm User'
      argument :token, !types.String
      resolve Resolvers::Users::Confirm.new
    end
    field :updateCurrentUser do
      type Types::UserType
      description 'Update CurrentUser'
      argument :data, InputTypes::UserType
      resolve Resolvers::Users::Update.new
    end
  end
end
