# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentPowerRanges
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            low: ComponentPowerRangeEntry,
            medium: ComponentPowerRangeEntry,
            high: ComponentPowerRangeEntry
          },
          additionalProperties: false
        })
      end
    end
  end
end
