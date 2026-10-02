# frozen_string_literal: true

module V1
  module Schemas
    class ShopItems < ::Shared::V1::Schemas::BaseList
      include OpenapiRuby::Components::Base

      schema({
        properties: {
          items: {type: :array, items: {"$ref": "#/components/schemas/ShopItem"}}
        },
        required: %w[items]
      })
    end
  end
end
