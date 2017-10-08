# encoding: utf-8
# frozen_string_literal: true

Types::ModelRoleType = GraphQL::ObjectType.define do
  name 'ModelRole'

  field :name, types.String
  field :slug, types.String
end
