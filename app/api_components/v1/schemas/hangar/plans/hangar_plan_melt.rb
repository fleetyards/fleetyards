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
              vehicleMissing: {type: :boolean},
              pledgeName: {type: [:string, :null], description: "The name of the pledge the ship came in, as RSI lists it"},
              pledgeShips: {
                type: :array,
                description: "The other ships of the same pledge, which melt with it",
                items: ::V1::Schemas::Hangar::Plans::HangarPlanPledgeShip
              },
              pledgeItems: {
                type: :array,
                description: "The paints, flair, gear and upgrades of the same pledge the hangar sync read, which melt with it",
                items: ::V1::Schemas::Hangar::Plans::HangarPlanPledgeItem
              }
            },
            additionalProperties: false,
            required: %w[id model estimated vehicleMissing pledgeShips pledgeItems]
          })
        end
      end
    end
  end
end
