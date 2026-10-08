# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Discord
        class FleetDiscordRoleMappings
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              items: {type: :array, items: ::V1::Schemas::Fleets::Discord::FleetDiscordRoleMapping}
            },
            additionalProperties: false,
            required: %w[items]
          })
        end
      end
    end
  end
end
