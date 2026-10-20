# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # Another mission, as much of it as a link needs.
      class GameMissionLink
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: [:string, :null]},
            slug: {type: :string}
          },
          additionalProperties: false,
          required: %w[id slug]
        })
      end
    end
  end
end
