# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanVehicleStatus
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              vehicleId: {type: :string, format: :uuid},
              name: {type: [:string, :null]},
              model: ::V1::Schemas::Hangar::Plans::HangarPlanModel,
              status: ::V1::Schemas::Enums::HangarPlanVehicleStatusEnum,
              targetModel: ::V1::Schemas::Hangar::Plans::HangarPlanModel,
              pledgeName: {type: [:string, :null], description: "The RSI pledge the ship came in, where the hangar sync kept its name"},
              standalone: {type: [:boolean, :null], description: "Whether the pledge holds the ship alone rather than a package; null where the hangar sync never saw it"},
              meltable: {type: [:boolean, :null], description: "Whether RSI lets the ship's pledge be melted; null until the hangar sync has read it"},
              pledgeItemCount: {type: [:integer, :null], description: "How many items the pledge holds, as RSI counts them"},
              pledgeShips: {
                type: :array,
                description: "The other ships of the same pledge",
                items: ::V1::Schemas::Hangar::Plans::HangarPlanPledgeShip
              },
              pledgeItems: {
                type: :array,
                description: "The paints, flair, gear and upgrades of the same pledge the hangar sync read",
                items: ::V1::Schemas::Hangar::Plans::HangarPlanPledgeItem
              }
            },
            additionalProperties: false,
            required: %w[vehicleId model status pledgeShips pledgeItems]
          })
        end
      end
    end
  end
end
