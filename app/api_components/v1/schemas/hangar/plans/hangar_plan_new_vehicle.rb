# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanNewVehicle
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              vehicleId: {type: :string, format: :uuid},
              name: {type: [:string, :null]},
              model: ::V1::Schemas::Hangar::Plans::HangarPlanModel
            },
            additionalProperties: false,
            required: %w[vehicleId model]
          })
        end
      end
    end
  end
end
