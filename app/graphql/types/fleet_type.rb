# encoding: utf-8
# frozen_string_literal: true

Types::FleetType = GraphQL::ObjectType.define do
  name 'Fleet'

  field :name, !types.String
  field :sid, !types.String
  field :logo, types.String
  field :members, types[!Types::FleetMemberType]
  field :archetype, !types.String
  field :mainActivity, !types.String, property: :main_activity
  field :secondaryActivity, !types.String, property: :secondary_activity
  field :recruiting, !types.Boolean
  field :commitment, !types.String
  field :rpg, !types.Boolean
  field :exclusive, !types.Boolean
  field :memberCount, !types.Int, property: :member_count
  field :createdAt, !types.String, property: :created_at
  field :updatedAt, !types.String, property: :updated_at
end
