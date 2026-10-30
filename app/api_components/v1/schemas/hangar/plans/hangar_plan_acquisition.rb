# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanAcquisition
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            description: "How one ship of a slot is obtained: a start, then upgrades until it is the planned ship",
            properties: {
              id: {type: :string, format: :uuid},
              startKind: ::V1::Schemas::Enums::HangarPlanStartKindEnum,
              sourceVehicleId: {type: [:string, :null], format: :uuid},
              buybackPledgeId: {type: [:string, :null], format: :uuid},
              startModel: ::V1::Schemas::Hangar::Plans::HangarPlanModel,
              priceOverride: {type: [:number, :null]},
              price: {type: [:number, :null], description: "What starting this way costs in USD; null when unknown"},
              routeComplete: {type: :boolean, description: "Whether the start and its upgrades end on the slot's ship; false while the route has yet to be planned"},
              sourceMissing: {type: :boolean},
              usesBuybackToken: {type: :boolean, description: "Pays for this buy-back with store credit, which spends one of the user's buy-back tokens"},
              steps: {type: :array, items: ::V1::Schemas::Hangar::Plans::HangarPlanUpgradeStep}
            },
            additionalProperties: false,
            required: %w[id startKind startModel routeComplete sourceMissing usesBuybackToken steps]
          })
        end
      end
    end
  end
end
