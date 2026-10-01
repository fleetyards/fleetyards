# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # A place a mission can take place at, and how we know.
      class GameMissionLocation
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            location: ::Shared::V1::Schemas::LocationLink,
            source: ::Shared::V1::Schemas::Enums::GameMissionLocationSourceEnum
          },
          additionalProperties: false,
          required: %w[location source]
        })
      end
    end
  end
end
