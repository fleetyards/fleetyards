# frozen_string_literal: true

module V1
  module Schemas
    # How a place is drawn: a body as a globe in its colour, a star or a
    # system as a sun. `color` and `bodyType` are absent where it has none.
    class SearchAppearance
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          kind: ::Shared::V1::Schemas::Enums::LocationKindEnum,
          color: {type: :string},
          bodyType: {type: :string},
          flare: {type: :boolean}
        },
        additionalProperties: false,
        required: %w[kind flare]
      })
    end
  end
end
