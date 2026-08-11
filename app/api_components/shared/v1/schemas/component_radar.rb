# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentRadar
        include OpenapiRuby::Components::Base

        SIGNATURE_SENSITIVITY = {
          type: :object,
          properties: {
            sensitivity: {type: :number},
            piercing: {type: :number}
          },
          additionalProperties: false
        }.freeze

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
            signatureDetection: {
              type: :object,
              properties: {
                ir: SIGNATURE_SENSITIVITY,
                em: SIGNATURE_SENSITIVITY,
                cs: SIGNATURE_SENSITIVITY,
                rs: SIGNATURE_SENSITIVITY
              },
              additionalProperties: false
            },
            pingProperties: {
              type: :object,
              properties: {
                cooldownTime: {type: :number}
              },
              additionalProperties: false
            },
            aimAssistRange: {type: :number},
            aimAssistMin: {type: :number},
            sensitivityModifiers: {
              type: :object,
              properties: {
                sensitivityAddition: {type: :number}
              },
              additionalProperties: false
            },
            powerConsumption: {type: :number},
            powerMinimumFraction: {type: :number},
            powerRanges: POWER_RANGES,
            signatureEm: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
