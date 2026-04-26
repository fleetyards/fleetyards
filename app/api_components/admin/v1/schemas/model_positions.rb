# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class ModelPositions < ::Shared::V1::Schemas::BaseList
        include OpenapiRuby::Components::Base

        schema({
          properties: {
            items: {type: :array, items: {"$ref": "#/components/schemas/ModelPosition"}}
          },
          required: %w[items]
        })
      end
    end
  end
end
