# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetDiscordRoleMappingInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            fleetRoleId: {type: :string, format: :uuid},
            discordRoleId: {type: [:string, :null], description: "`null` clears the mapping."}
          },
          required: %w[fleetRoleId discordRoleId],
          additionalProperties: false
        })
      end
    end
  end
end
