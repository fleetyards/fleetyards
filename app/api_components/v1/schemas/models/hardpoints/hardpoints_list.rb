# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Hardpoints
        class HardpointsList
          include OpenapiRuby::Components::Base

          schema({
            type: :array,
            items: {"$ref": "#/components/schemas/Hardpoint"}
          })
        end
      end
    end
  end
end
