# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class HangarMetrics
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            totalMoney: {type: :number},
            totalCredits: {type: :number},
            totalIngameValue: {type: :number},
            totalMinCrew: {type: :integer},
            totalMaxCrew: {type: :integer},
            totalCargo: {type: :number},
            largestShip: {type: :number, nullable: true},
            smallestShip: {type: :number, nullable: true},
            averagePledgePrice: {type: :number},
            flightReadyCount: {type: :integer},
            uniqueModelsCount: {type: :integer},
            manufacturerCount: {type: :integer},
            missingClassifications: {type: :array, items: {type: :string}},
            wishlistTotalMoney: {type: :number},
            wishlistTotalCredits: {type: :number}
          },
          additionalProperties: false,
          required: %w[totalMoney totalCredits totalIngameValue totalMinCrew totalMaxCrew
            totalCargo averagePledgePrice flightReadyCount uniqueModelsCount
            manufacturerCount missingClassifications wishlistTotalMoney wishlistTotalCredits]
        })
      end
    end
  end
end
