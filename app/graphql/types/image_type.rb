# encoding: utf-8
# frozen_string_literal: true

Types::ImageType = GraphQL::ObjectType.define do
  name 'Image'

  field :id, !types.String
  field :name, !types.String do
    resolve ->(obj, _args, _ctx) { obj.name.file.filename }
  end
  field :url, !types.String do
    resolve ->(obj, _args, _ctx) { obj.name.url }
  end
  field :type, !types.String do
    resolve ->(obj, _args, _ctx) { obj.name.content_type }
  end
  field :smallURL, !types.String do
    resolve ->(obj, _args, _ctx) { obj.name.small.url }
  end
  field :bigURL, !types.String do
    resolve ->(obj, _args, _ctx) { obj.name.big.url }
  end
  field :darkURL, !types.String do
    resolve ->(obj, _args, _ctx) { obj.name.dark.url }
  end

  field :model, Types::ModelType, property: :gallery

  field :createdAt, !types.String, property: :created_at
  field :updatedAt, !types.String, property: :updated_at
end
