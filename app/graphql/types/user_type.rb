# encoding: utf-8
# frozen_string_literal: true

Types::UserType = GraphQL::ObjectType.define do
  name 'User'

  field :id, !types.String
  field :email, !types.String
  field :username, !types.String
  field :avatar, types.String
  field :isAdmin, !types.Boolean, property: :is_admin
  field :rsiHandle, types.String, property: :rsi_handle
  field :rsiOrg, types.String, property: :rsi_org
  field :saleNotify, !types.Boolean, property: :sale_notify
  field :createdAt, !types.String, property: :created_at
  field :updatedAt, !types.String, property: :updated_at
end
