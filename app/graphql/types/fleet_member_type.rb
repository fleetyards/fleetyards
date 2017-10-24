# encoding: utf-8
# frozen_string_literal: true

Types::FleetMemberType = GraphQL::ObjectType.define do
  name 'FleetMember'

  field :username, !types.String do
    resolve ->(obj, _args, _ctx) { obj.user.username }
  end
  field :admin, !types.Boolean
  field :approved, !types.Boolean
  field :createdAt, !types.String, property: :created_at
  field :updatedAt, !types.String, property: :updated_at
end
