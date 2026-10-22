# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanMetrics
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              total: {type: :integer},
              uniqueModelsCount: {type: :integer},
              manufacturerCount: {type: :integer},
              totalCrew: {type: :integer},
              totalCargo: {type: :number},
              totalPledgeValue: {type: :number},
              flightReadyCount: {type: :integer},
              largestShip: {type: [:number, :null]},
              smallestShip: {type: [:number, :null]},
              classifications: {type: :array, items: ::V1::Schemas::Hangar::Plans::HangarPlanCount},
              sizes: {type: :array, items: ::V1::Schemas::Hangar::Plans::HangarPlanCount},
              productionStatuses: {type: :array, items: ::V1::Schemas::Hangar::Plans::HangarPlanCount},
              manufacturers: {type: :array, items: ::V1::Schemas::Hangar::Plans::HangarPlanCount}
            },
            additionalProperties: false,
            required: %w[total uniqueModelsCount manufacturerCount totalCrew totalCargo totalPledgeValue flightReadyCount classifications sizes productionStatuses manufacturers]
          })
        end
      end
    end
  end
end
