# encoding: utf-8
# frozen_string_literal: true

Types::UserType = GraphQL::ObjectType.define do
  name 'User'

  field :id, !types.String
  field :email, !types.String
  field :username, !types.String
  field :avatar, types.String
  field :isAdmin, !types.Boolean, property: :admin?
  field :rsiHandle, types.String, property: :rsi_handle
  field :fleets, types[!types.String] do
    resolve ->(obj, _args, _ctx) { obj.fleets.map(&:sid) }
  end
  field :pendingFleets, types[!types.String] do
    resolve ->(obj, _args, _ctx) { obj.pending_fleets.map(&:sid) }
  end
  field :adminFleets, types[!types.String] do
    resolve ->(obj, _args, _ctx) { obj.admin_fleets.map(&:sid) }
  end
  field :saleNotify, !types.Boolean, property: :sale_notify
  field :createdAt, !types.String, property: :created_at
  field :updatedAt, !types.String, property: :updated_at
end
