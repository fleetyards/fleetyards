# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # A part with no figures of its own beyond the salvage controller's: a
      # filler station, the Moth's tool arm.
      class ComponentSalvageCarrier
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            salvage: ComponentSalvagePart
          },
          required: %w[salvage],
          additionalProperties: false
        })
      end
    end
  end
end
