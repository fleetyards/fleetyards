# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # The material a cost line resolves to. Null where the commodity
      # catalogue has no row for it, which is what `commodityKey` still
      # answers.
      class BlueprintCostCommodity
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},

            # What one piece takes up, in SCU, where the game counts this
            # material in pieces. It is the rate between the unit a recipe
            # states a cost in and the unit a holding may be recorded in, so
            # without it the two cannot be compared at all. Null for a bulk
            # material, which has no single piece to measure.
            pieceVolume: {type: [:number, :null]}
          },
          additionalProperties: false,
          required: %w[id name slug]
        })
      end
    end
  end
end
