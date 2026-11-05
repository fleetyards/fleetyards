# frozen_string_literal: true

module V1
  module Schemas
    class Faction
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          slug: {type: :string},
          name: {type: :string},

          # "neutral" is ours to name: the export states a boolean.
          alignment: ::Shared::V1::Schemas::Enums::NullableBlueprintSourceAlignmentEnum,
          area: {type: [:string, :null]},
          focus: {type: [:string, :null]},
          logo: ::Shared::V1::Schemas::MediaFile,

          # The released missions this faction offers.
          missionCount: {type: :integer}
        },
        additionalProperties: false,
        required: %w[id slug name missionCount]
      })
    end
  end
end
