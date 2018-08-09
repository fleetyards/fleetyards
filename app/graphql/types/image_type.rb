# frozen_string_literal: true

Types::ImageType = GraphQL::ObjectType.define do
  name 'Image'

  field :id, types.String
  field :name, types.String do
    resolve ->(obj, _args, _ctx) do
      obj.name.file.filename
    end
  end
  field :url, types.String do
    resolve ->(obj, _args, _ctx) do
      obj.name.url
    end
  end
  field :type, types.String do
    resolve ->(obj, _args, _ctx) do
      obj.name.content_type
    end
  end
  field :background, types.Boolean
  field :smallURL, types.String do
    resolve ->(obj, _args, _ctx) do
      obj.name.small.url
    end
  end
  field :bigURL, types.String do
    resolve ->(obj, _args, _ctx) do
      obj.name.big.url
    end
  end
  field :model, Types::ModelType do
    resolve ->(obj, _args, _ctx) do
      obj.gallery if obj.gallery_type == 'Model'
    end
  end
end
