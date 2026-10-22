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
              candidates: {type: :array, items: ::V1::Schemas::Hangar::Plans::HangarPlanCandidate}
            },
            additionalProperties: false,
            required: %w[id label quantity position state filters candidates]
          })
        end
      end
    end
  end
end
