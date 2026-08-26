# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class VehicleLoadoutHardpoint
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            modelHardpointId: {type: :string, format: :uuid},
            hardpoint: {"$ref": "#/components/schemas/ModelHardpoint"},
            component: {"$ref": "#/components/schemas/Component"}
          }
        })
      end
    end
  end
end
