# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class Blueprints < ::Shared::V1::Schemas::BaseList
        include OpenapiRuby::Components::Base

        schema({
          properties: {
            items: {type: :array, items: {"$ref": "#/components/schemas/Blueprint"}}
          },
          required: %w[items]
        })
      end
    end
  end
end
