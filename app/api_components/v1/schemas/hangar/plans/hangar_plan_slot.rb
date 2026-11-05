# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanSlot
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              label: {type: :string},
              description: {type: [:string, :null]},
              filters: ::V1::Schemas::Hangar::Plans::HangarPlanSlotFilters,
              quantity: {type: :integer},
              position: {type: :integer},
              state: ::V1::Schemas::Enums::HangarPlanSlotStateEnum,
              candidates: {type: :array, items: ::V1::Schemas::Hangar::Plans::HangarPlanCandidate},
              starts: {type: :array, items: ::V1::Schemas::Hangar::Plans::HangarPlanSlotStart, description: "Starts picked while the slot has no ship; its first ship takes them"}
            },
            additionalProperties: false,
            required: %w[id label quantity position state filters candidates starts]
          })
        end
      end
    end
  end
end
