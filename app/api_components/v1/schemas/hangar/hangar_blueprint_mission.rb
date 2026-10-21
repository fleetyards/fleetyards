# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      # A mission that can hand out a blueprint on the reader's wishlist, and
      # which of the wanted ones it can. The mission is nested whole, like a
      # fleet blueprint nests its recipe, so the catalogue's row renders it.
      class HangarBlueprintMission
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            mission: ::Shared::V1::Schemas::GameMission,
            wantedBlueprints: {type: :array, items: ::Shared::V1::Schemas::GameMissionBlueprint}
          },
          additionalProperties: false,
          required: %w[id mission wantedBlueprints]
        })
      end
    end
  end
end
