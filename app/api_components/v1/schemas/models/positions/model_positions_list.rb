# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Positions
        class ModelPositionsList
          include OpenapiRuby::Components::Base

          schema({
            type: :array,
            items: {"$ref": "#/components/schemas/ModelPosition"}
          })
        end
      end
    end
  end
end
