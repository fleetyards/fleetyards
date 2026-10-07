# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Discord
        class FleetDiscordRole
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string},
              name: {type: :string}
            },
            additionalProperties: false,
            required: %w[id name]
          })
        end
      end
    end
  end
end
