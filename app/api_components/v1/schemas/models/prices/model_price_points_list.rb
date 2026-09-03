# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Prices
        class ModelPricePointsList
          include OpenapiRuby::Components::Base

          schema({
            type: :array,
            items: {"$ref": "#/components/schemas/ModelPricePoint"}
          })
        end
      end
    end
  end
end
