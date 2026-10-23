# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanVehicleResource
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: [:string, :null]},
              model: ::V1::Schemas::Hangar::Plans::HangarPlanModel,
              usedBy: ::V1::Schemas::Enums::NullableHangarPlanVehicleUseEnum,
              meltable: {type: [:boolean, :null], description: "Whether RSI lets the ship's pledge be melted; null until the hangar sync has read it"},
              meltValue: {type: [:number, :null], description: "The store credit melting the ship's pledge gives, as RSI lists it"},
              pledgeItemCount: {type: [:integer, :null], description: "How many items the pledge holds; melting the ship melts them all"},
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
            required: %w[id model pledgeShips pledgeItems]
          })
        end
      end
    end
  end
end
