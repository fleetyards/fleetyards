# encoding: utf-8
# frozen_string_literal: true

module Queries
  Images = GraphQL::ObjectType.define do
    field :images do
      type types[!Types::ImageType]
      description 'All Images'
      resolve ->(_obj, _args, _ctx) { Image.enabled.in_gallery.order("images.created_at desc") }
    end
  end
end
