# encoding: utf-8
# frozen_string_literal: true

Types::CitizenType = GraphQL::ObjectType.define do
  name 'Citizen'

  field :username, !types.String
  field :handle, !types.String
  field :avatar, !types.String
  field :title, !types.String
  field :enlisted, !types.String
  field :citizenRecord, !types.String, property: :citizen_record
  field :location, !types.String
  field :languages, !types.String
  field :createdAt, !types.String, property: :created_at
  field :updatedAt, !types.String, property: :updated_at
end
