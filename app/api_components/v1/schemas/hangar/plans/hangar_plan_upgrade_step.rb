# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanUpgradeStep
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              sourceKind: ::V1::Schemas::Enums::HangarPlanUpgradeSourceEnum,
              fromModel: ::V1::Schemas::Hangar::Plans::HangarPlanModel,
              toModel: ::V1::Schemas::Hangar::Plans::HangarPlanModel,
              hangarPledgeItemId: {type: [:string, :null], format: :uuid},
              buybackPledgeId: {type: [:string, :null], format: :uuid},
              priceOverride: {type: [:number, :null]},
              price: {type: [:number, :null], description: "In USD; null when a store price is unknown"},
              sourceMissing: {type: :boolean}
            },
            additionalProperties: false,
            required: %w[id sourceKind fromModel toModel sourceMissing]
          })
        end
      end
    end
  end
end
