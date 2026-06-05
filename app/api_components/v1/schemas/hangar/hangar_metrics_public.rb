# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class HangarMetricsPublic
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            totalMinCrew: {type: :integer},
            totalMaxCrew: {type: :integer},
            totalCargo: {type: :number},
            largestShip: {type: :number},
            smallestShip: {type: :number},
            flightReadyCount: {type: :integer},
            uniqueModelsCount: {type: :integer},
            manufacturerCount: {type: :integer},
            missingClassifications: {type: :array, items: {type: :string}}
          },
          additionalProperties: false,
          required: %w[totalMinCrew totalMaxCrew
            totalCargo flightReadyCount uniqueModelsCount
            manufacturerCount missingClassifications]
        })
      end
    end
  end
end
