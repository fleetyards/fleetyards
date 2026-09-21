# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # One thing a mission pays.
      #
      # Most fields are populated for exactly one `kind`, which is why only
      # `kind` is required: a reputation entry states an amount and an org, an
      # item states an entity class, a badge states a key and nothing else.
      class GameMissionReward
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            kind: ::Shared::V1::Schemas::Enums::GameMissionRewardKindEnum,

            # Reputation points, an item count, or aUEC. Negative for a
            # reputation loss: 16 of the 58 amounts the export declares are,
            # because work for one side costs standing with the other.
            amount: {type: [:integer, :null]},

            # The top of a stated range, and only ever set alongside a currency
            # amount. A `max` of zero in the export is the field unset rather
            # than a ceiling of nothing, and is not carried.
            max: {type: [:integer, :null]},

            # "UEC" on seven of the eight contracts that state a figure, and
            # "MER" -- mercenary scrip -- on the other. Null where the game
            # works the figure out itself.
            currency: {type: [:string, :null]},

            # Currency only: the game sets the amount when it generates the
            # mission, so the contract says that it pays without saying how
            # much. True for 2352 of the 2360 that pay.
            calculated: {type: :boolean},

            # Reputation only: whose standing moves, which is not always the
            # org offering the contract.
            orgName: {type: [:string, :null]},
            orgKey: {type: [:string, :null]},

            # Item only. Not resolved to a catalogue row: an award names things
            # that are variously equipment, a commodity crate, or a mission
            # carryable in no catalogue at all.
            entityClass: {type: [:string, :null]},

            # What that entity is called, resolved by the parser against the
            # export's own entity tree -- 405 of the 410 awards resolve. The two
            # commonest are physical currency, "MG Scrip" and "Council Scrip",
            # which is the closest the export comes to stating a payout per
            # contract.
            entityName: {type: [:string, :null]},

            # Item only, and only where the award is drawn from weighted sets:
            # which set this entry belonged to, so a page can say one of these
            # rather than all of them.
            weight: {type: [:number, :null]},

            # Badge only. The export states the key and nothing that resolves
            # it to a name or a picture.
            badge: {type: [:string, :null]}
          },
          additionalProperties: false,
          required: %w[kind]
        })
      end
    end
  end
end
