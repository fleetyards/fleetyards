# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Discord
        class FleetDiscordChannel
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string},
              name: {type: :string},
              parentName: {type: [:string, :null]}
            },
            additionalProperties: false,
            required: %w[id name parentName]
          })
        end
      end
    end
  end
end
