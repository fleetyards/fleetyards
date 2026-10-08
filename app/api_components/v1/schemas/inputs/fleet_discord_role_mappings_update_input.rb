# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetDiscordRoleMappingsUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            mappings: {type: :array, items: ::V1::Schemas::Inputs::FleetDiscordRoleMappingInput}
          },
          required: %w[mappings],
          additionalProperties: false,
          description: "Ranks not listed keep their mapping."
        })
      end
    end
  end
end
