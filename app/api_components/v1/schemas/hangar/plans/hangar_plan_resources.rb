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
              buybacks: {type: :array, items: ::V1::Schemas::Hangar::Plans::HangarPlanBuybackResource}
            },
            additionalProperties: false,
            required: %w[vehicles upgrades buybacks]
          })
        end
      end
    end
  end
end
