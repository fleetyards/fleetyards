# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # A recipe a mission hands out. Named rather than linked by id alone: the
      # page renders the list, and a second request per row to learn what each
      # one is called would be the whole payload's cost again.
      class GameMissionBlueprint
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
