# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanVehicleMark
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              vehicleId: {type: :string, format: :uuid},
              mark: ::V1::Schemas::Enums::HangarPlanVehicleMarkEnum
            },
            additionalProperties: false,
            required: %w[id vehicleId mark]
          })
        end
      end
    end
  end
end
