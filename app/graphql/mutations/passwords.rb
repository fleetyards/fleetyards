# encoding: utf-8
# frozen_string_literal: true

module Mutations
  Passwords = GraphQL::ObjectType.define do
    field :requestPasswordChange do
      type Types::ResultType
      description 'Request Password Change'
      argument :email, !types.String
      resolve Resolvers::Passwords::RequestChange.new
    end
    field :updatePassword do
      type Types::ResultType
      description 'Update Password'
      argument :data, !InputTypes::ChangePasswordType
      resolve Resolvers::Passwords::Update.new
    end
  end
end
