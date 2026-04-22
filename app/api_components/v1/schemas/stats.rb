# frozen_string_literal: true

module V1
  module Schemas
    class Stats
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          shipsCountYear: {type: :integer},
          shipsCountTotal: {type: :integer},
          manufacturerCount: {type: :integer},
          flightReadyCount: {type: :integer},
          averagePledgePrice: {type: :integer},
          largestShip: {type: :number, nullable: true},
          smallestShip: {type: :number, nullable: true},
          vehiclesCount: {type: :integer},
          wishlistsCount: {type: :integer},
          shipOfTheMonth: {type: :string, nullable: true},
          shipOfTheMonthCount: {type: :integer}
        },
        additionalProperties: false,
        required: %w[shipsCountYear shipsCountTotal manufacturerCount flightReadyCount
          averagePledgePrice vehiclesCount wishlistsCount shipOfTheMonthCount]
      })
    end
  end
end
