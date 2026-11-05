# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # The org offering the work. A component of its own rather than an inline
      # object: Orval names an anonymous nested shape after its owner and
      # reproduces it once per owner.
      class GameMissionOrg
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},

            # The reputation record's own element name, which is what curation
            # keys off -- a GUID is an identity the export is free to reissue
            # and the display name is localised.
            key: {type: [:string, :null]},

            # "neutral" is ours to name: the export states a boolean and there
            # is no third value anywhere in the tree.
            alignment: ::Shared::V1::Schemas::Enums::NullableBlueprintSourceAlignmentEnum,

            # What that boolean says, unmediated.
            lawful: {type: [:boolean, :null]}
          },
          additionalProperties: false,
          required: %w[name]
        })
      end
    end
  end
end
