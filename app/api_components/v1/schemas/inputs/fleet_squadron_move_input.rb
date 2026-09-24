# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetSquadronMoveInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            position: {type: :integer, minimum: 0, description: "Zero-based place in the fleet's order, squadrons and teams counted together"}
          },
          required: %w[position],
          additionalProperties: false
        })
      end
    end
  end
end
