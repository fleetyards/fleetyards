# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanSlotStart
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            description: "A start picked for a slot that has no ship yet",
            properties: {
              id: {type: :string, format: :uuid},
              startKind: ::V1::Schemas::Enums::HangarPlanStartKindEnum,
              sourceVehicleId: {type: [:string, :null], format: :uuid},
              buybackPledgeId: {type: [:string, :null], format: :uuid},
              startModel: {
                anyOf: [::V1::Schemas::Hangar::Plans::HangarPlanModel, {type: :null}],
                description: "Unset for a ship to buy or earn, which is whichever ship the slot gets"
              },
              sourceMissing: {type: :boolean}
            },
            additionalProperties: false,
            required: %w[id startKind startModel sourceMissing]
          })
        end
      end
    end
  end
end
