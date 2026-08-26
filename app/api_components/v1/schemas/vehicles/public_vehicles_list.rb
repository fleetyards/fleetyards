# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class PublicVehiclesList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: {"$ref": "#/components/schemas/VehiclePublic"}
        })
      end
    end
  end
end
