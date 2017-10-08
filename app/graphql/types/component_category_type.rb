# encoding: utf-8
# frozen_string_literal: true

Types::ComponentCategoryType = GraphQL::ObjectType.define do
  name 'ComponentCategory'

  field :id, !types.String
  field :name, !types.String
  field :slug, !types.String
end
