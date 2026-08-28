# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class ScDataUnlistedModel
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            identifier: {type: :string},
            name: {type: [:string, :null]},

            # What a model made from this entry would be called: the export
            # prefixes the manufacturer and Fleetyards does not.
            suggestedName: {type: :string},

            # How the export's version compares to the ship it extends.
            # Descriptive rather than a verdict: the game files never say whether
            # a player can own something, which is the only question that
            # decides whether this becomes a model.
            comparison: ::Admin::V1::Schemas::Enums::UnlistedModelComparisonEnum,
            decision: ::Admin::V1::Schemas::Enums::UnlistedModelDecisionEnum,
            decidedAt: {type: [:string, :null], format: "date-time"},

            firstSeenVersion: {type: :string},
            lastSeenVersion: {type: :string},
            environment: {type: :string},

            # Blank when the identifier names a prefix no ship in the catalogue
            # uses -- a new company, or a file that is not a ship at all.
            manufacturerCode: {type: [:string, :null]},
            manufacturer: {oneOf: [::Admin::V1::Schemas::ScDataUnlistedModels::ManufacturerRef, {type: :null}]},

            baseModel: {oneOf: [::Admin::V1::Schemas::Models::ModelRef, {type: :null}]},

            # A ship of that name already in the catalogue, and a livery of that
            # name already on the ship this extends. Either means the work is
            # done and the entry only needs a decision, not a creation.
            existingModel: {oneOf: [::Admin::V1::Schemas::Models::ModelRef, {type: :null}]},
            existingPaint: {oneOf: [::Admin::V1::Schemas::Models::ModelRef, {type: :null}]},
            model: {oneOf: [::Admin::V1::Schemas::Models::ModelRef, {type: :null}]},

            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id identifier suggestedName firstSeenVersion lastSeenVersion environment createdAt updatedAt]
        })
      end
    end
  end
end
