# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanDrift
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              basedOnAt: {type: :string, format: "date-time"},
              missingSources: {type: :array, items: ::V1::Schemas::Hangar::Plans::HangarPlanSourceIssue},
              changedSources: {type: :array, items: ::V1::Schemas::Hangar::Plans::HangarPlanSourceIssue},
              newVehicles: {type: :array, items: ::V1::Schemas::Hangar::Plans::HangarPlanNewVehicle},
              previousTotal: {type: :number, description: "Net cost of the decided routes as priced when planned"},
              currentTotal: {type: :number, description: "Net cost of the decided routes at today's prices"},
              drifted: {type: :boolean}
            },
            additionalProperties: false,
            required: %w[basedOnAt missingSources changedSources newVehicles previousTotal currentTotal drifted]
          })
        end
      end
    end
  end
end
