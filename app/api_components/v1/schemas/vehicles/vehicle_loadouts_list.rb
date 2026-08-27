# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class VehicleLoadoutsList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: {"$ref": "#/components/schemas/VehicleLoadout"}
        })
      end
    end
  end
end
