# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class HangarPlanVehicleMarkCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            vehicleId: {type: :string, format: :uuid},
            mark: ::V1::Schemas::Enums::HangarPlanVehicleMarkEnum
          },
          required: %w[vehicleId mark],
          additionalProperties: false
        })
      end
    end
  end
end
