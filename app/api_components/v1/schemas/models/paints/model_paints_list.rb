# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Paints
        class ModelPaintsList
          include OpenapiRuby::Components::Base

          schema({
            type: :array,
            items: {"$ref": "#/components/schemas/ModelPaint"}
          })
        end
      end
    end
  end
end
