# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # One thing a mission asks to be brought to it.
      class GameMissionHandIn
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            kind: ::Shared::V1::Schemas::Enums::GameMissionHandInKindEnum,

            # The entity class, group record or resource type the export names.
            # Not resolved to a catalogue row, for the reason a reward's is not.
            ref: {type: :string},
            name: {type: [:string, :null]},

            # A count for an item, SCU for a resource. `max` only where the
            # contract states a range.
            amount: {type: :integer},
            max: {type: [:integer, :null]},

            # Set where the contract offers a choice: entries sharing an option
            # are one alternative, and any one option satisfies it. Null is
            # always asked for.
            option: {type: [:integer, :null]}
          },
          additionalProperties: false,
          required: %w[kind ref amount]
        })
      end
    end
  end
end
