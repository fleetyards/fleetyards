# encoding: utf-8
# frozen_string_literal: true

Types::OrgType = GraphQL::ObjectType.define do
  name 'Org'

  field :id, !types.String
  field :name, !types.String
  field :sid, !types.String
  field :archetype, !types.String
  field :mainActivity, !types.String, property: :main_activity
  field :secondaryActivity, !types.String, property: :secondary_activity
  field :recruiting, !types.Boolean
  field :commitment, !types.String
  field :rpg, !types.Boolean
  field :exclusive, !types.Boolean
  field :logo, !types.String
  field :createdAt, !types.String, property: :created_at
  field :updatedAt, !types.String, property: :updated_at
end
