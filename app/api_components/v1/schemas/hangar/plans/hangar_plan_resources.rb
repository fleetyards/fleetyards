# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanResources
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              vehicles: {type: :array, items: ::V1::Schemas::Hangar::Plans::HangarPlanVehicleResource},
              upgrades: {type: :array, items: ::V1::Schemas::Hangar::Plans::HangarPlanUpgradeResource},
              buybacks: {type: :array, items: ::V1::Schemas::Hangar::Plans::HangarPlanBuybackResource},
              storeModels: {type: :array, items: ::V1::Schemas::Hangar::Plans::HangarPlanModel, description: "Every ship the pledge store prices, cheapest first"}
            },
            additionalProperties: false,
            required: %w[vehicles upgrades buybacks storeModels]
          })
        end
      end
    end
  end
end
