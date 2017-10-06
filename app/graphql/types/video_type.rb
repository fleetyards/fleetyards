# encoding: utf-8
# frozen_string_literal: true

Types::VideoType = GraphQL::ObjectType.define do
  name 'Video'

  field :id, !types.String
  field :url, !types.String
  field :type, !types.String, property: :video_type
  field :createdAt, !types.String, property: :created_at
  field :updatedAt, !types.String, property: :updated_at
end
