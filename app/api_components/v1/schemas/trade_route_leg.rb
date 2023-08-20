# frozen_string_literal: true

module V1
  module Schemas
    class TradeRouteLeg
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          name: {type: :string},
          slug: {type: :string},
          type: {"$ref": "#/components/schemas/StationTypeEnum"},
          locationLabel: {type: :string},
          shop: {type: :string},
          shopSlug: {type: :string},
          planet: {type: :string},
          planetSlug: {type: :string},
          starsystem: {type: :string},
          starsystemSlug: {type: :string}
        },
        additionalProperties: false,
        required: %w[name slug locationLabel shop shopSlug planet planetSlug starsystem starsystemSlug]
      })
    end
  end
end
