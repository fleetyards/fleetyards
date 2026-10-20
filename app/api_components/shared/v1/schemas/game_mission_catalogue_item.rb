# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # The catalogue row a reward or a hand-in names: enough to name it and
      # link to it, the way a recipe's output is served.
      class GameMissionCatalogueItem
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            type: ::Shared::V1::Schemas::Enums::GameMissionCatalogueItemTypeEnum,
            id: {type: :string, format: :uuid},
            name: {type: [:string, :null]},
            slug: {type: :string},
            # False for a hidden equipment variant, which has no public page.
            listed: {type: :boolean}
          },
          additionalProperties: false,
          required: %w[type id slug]
        })
      end
    end
  end
end
