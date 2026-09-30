# frozen_string_literal: true

module V1
  module Schemas
    class CatalogueTokenMatch
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        required: %i[token name type slug],
        properties: {
          token: {type: :string, description: "The token text between `[*` and `*]`, as written or to be inserted"},
          name: {type: :string},
          type: {type: :string, enum: %w[Component Equipment Commodity]},
          slug: {type: :string}
        }
      })
    end
  end
end
