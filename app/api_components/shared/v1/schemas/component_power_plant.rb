# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentPowerPlant
        include OpenapiRuby::Components::Base

        POWER_RANGE_ENTRY = {
          type: :object,
          properties: {
            start: {type: :number},
            modifier: {type: :number}
          },
          additionalProperties: false
        }.freeze

        POWER_RANGES = {
          type: :object,
          properties: {
            low: POWER_RANGE_ENTRY,
            medium: POWER_RANGE_ENTRY,
            high: POWER_RANGE_ENTRY
          },
          additionalProperties: false
        }.freeze

        schema({
          type: :object,
          properties: {
            powerBase: {type: :number},
            powerDraw: {type: :number},
            powerRanges: POWER_RANGES,
            signatureEm: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
