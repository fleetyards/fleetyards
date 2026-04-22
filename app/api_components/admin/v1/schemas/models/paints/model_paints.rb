# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        module Paints
          class ModelPaints < ::Shared::V1::Schemas::BaseList
            include OpenapiRuby::Components::Base

            schema({
              properties: {
                items: {type: :array, items: {"$ref": "#/components/schemas/ModelPaint"}}
              },
              required: %w[items]
            })
          end
        end
      end
    end
  end
end
