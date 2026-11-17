# frozen_string_literal: true

module V1
  module Schemas
    class StarSystem
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          # The game's name for the system, upper-cased: `STANTON`, `EL'SIN`.
          # What a fleet member's `currentSystemCode` holds.
          code: {type: :string},
          name: {type: :string},
          # Where RSI's online starmap draws the system, in its own unit.
          position: {type: :array, items: {type: :number}, minItems: 3, maxItems: 3},
          systemType: ::V1::Schemas::Enums::NullableStarSystemTypeEnum,
          affiliations: {type: :array, items: {type: :string}},
          # Whether the game ships the system.
          inGame: {type: :boolean}
        },
        additionalProperties: false,
        required: %w[code name position systemType affiliations inGame]
      })
    end
  end
end
