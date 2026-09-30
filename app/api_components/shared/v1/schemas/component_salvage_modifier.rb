# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # Multipliers a salvage modifier applies to the head's scraping beam.
      class ComponentSalvageModifier
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            salvageModifier: {type: :boolean},
            salvageSpeed: {type: :number},
            radius: {type: :number},
            extractionEfficiency: {type: :number}
          },
          required: %w[salvageModifier],
          additionalProperties: false
        })
      end
    end
  end
end
