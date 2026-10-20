# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanCandidate
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              position: {type: :integer},
              model: ::V1::Schemas::Hangar::Plans::HangarPlanModel,
              modelPaintId: {type: [:string, :null], format: :uuid},
              paintName: {type: [:string, :null]},
              modelModuleIds: {type: :array, items: {type: :string, format: :uuid}},
              modelUpgradeIds: {type: :array, items: {type: :string, format: :uuid}},
              matchesFilters: {type: :boolean, description: "Whether the ship meets every filter its slot sets"},
              ownedCount: {type: :integer, description: "Ships of this model in the hangar the plan does not use yet"},
              acquisitions: {type: :array, items: ::V1::Schemas::Hangar::Plans::HangarPlanAcquisition}
            },
            additionalProperties: false,
            required: %w[id position model modelModuleIds modelUpgradeIds matchesFilters ownedCount acquisitions]
          })
        end
      end
    end
  end
end
