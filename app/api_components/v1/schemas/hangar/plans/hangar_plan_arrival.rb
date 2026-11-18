# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanArrival
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            description: "A hangar ship an update takes as the one a route set out to get",
            properties: {
              acquisitionId: {type: :string, format: :uuid},
              vehicleId: {type: :string, format: :uuid},
              name: {type: [:string, :null]},
              model: ::V1::Schemas::Hangar::Plans::HangarPlanModel
            },
            additionalProperties: false,
            required: %w[acquisitionId vehicleId model]
          })
        end
      end
    end
  end
end
