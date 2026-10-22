# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanSlotCost
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              slotId: {type: :string, format: :uuid},
              state: ::V1::Schemas::Enums::HangarPlanSlotStateEnum,
              minCost: {type: :number},
              maxCost: {type: :number},
              unresolvedCount: {type: :integer},
              complete: {type: :boolean}
            },
            additionalProperties: false,
            required: %w[slotId state minCost maxCost unresolvedCount complete]
          })
        end
      end
    end
  end
end
