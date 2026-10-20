# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanMelt
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              vehicleId: {type: :string, format: :uuid},
              vehicleName: {type: [:string, :null]},
              model: ::V1::Schemas::Hangar::Plans::HangarPlanModel,
              valueOverride: {type: [:number, :null]},
              value: {type: [:number, :null]},
              estimated: {type: :boolean, description: "True when the credit is today's store price rather than what the user entered"},
              vehicleMissing: {type: :boolean}
            },
            additionalProperties: false,
            required: %w[id vehicleId model estimated vehicleMissing]
          })
        end
      end
    end
  end
end
