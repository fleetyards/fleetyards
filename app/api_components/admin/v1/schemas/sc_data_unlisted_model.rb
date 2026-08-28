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
            model: {oneOf: [::Admin::V1::Schemas::Models::ModelRef, {type: :null}]},

            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id identifier firstSeenVersion lastSeenVersion environment createdAt updatedAt]
        })
      end
    end
  end
end
