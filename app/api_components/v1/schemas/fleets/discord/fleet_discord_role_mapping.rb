# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Discord
        class FleetDiscordRoleMapping
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              fleetRoleId: {type: :string, format: :uuid},
              name: {type: :string},
              discordRoleId: {type: :string, nullable: true}
            },
            additionalProperties: false,
            required: %w[fleetRoleId name discordRoleId]
          })
        end
      end
    end
  end
end
