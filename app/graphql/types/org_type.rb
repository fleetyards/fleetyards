# encoding: utf-8
# frozen_string_literal: true

Types::OrgType = GraphQL::ObjectType.define do
  name 'Org'

  field :name, !types.String
  field :sid, !types.String
  field :logo, !types.String
  field :memberCount, types.Int, property: :member_count
  field :mainActivity, !types.String, property: :main_activity
  field :secondaryActivity, !types.String, property: :secondary_activity
end
