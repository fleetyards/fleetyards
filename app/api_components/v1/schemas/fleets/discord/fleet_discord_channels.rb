# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Discord
        class FleetDiscordChannels
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              code: ::V1::Schemas::Enums::FleetDiscordConnectionCodeEnum,
              items: {type: :array, items: ::V1::Schemas::Fleets::Discord::FleetDiscordChannel}
            },
            additionalProperties: false,
            required: %w[code items]
          })
        end
      end
    end
  end
end
