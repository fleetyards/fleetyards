# frozen_string_literal: true

module V1
  module Schemas
    # What the current patch brought: the newest live build against the last
    # build of the patch before it, with both values of every fact that moved.
    #
    # Facts we derive ourselves are left out, because a change to our formula
    # changes every record at once and says nothing about the patch.
    class ScDataPatchSummary
      include OpenapiRuby::Components::Base

      VALUE = {type: [:number, :string, :boolean, :null]}.freeze

      SHIP = {
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string},
          slug: {type: :string},
          manufacturerName: {type: :string},
          storeImage: ::Shared::V1::Schemas::MediaFile,
          previewImage: ::Shared::V1::Schemas::MediaFile
        },
        additionalProperties: false,
        required: %w[id name slug]
      }.freeze

      FIELD = {
        type: :object,
        properties: {
          field: {type: :string},
          from: VALUE,
          to: VALUE
        },
        additionalProperties: false,
        required: %w[field from to]
      }.freeze

      schema({
        type: :object,
        properties: {
          from: ::V1::Schemas::ScDataCompare::BUILD,
          to: ::V1::Schemas::ScDataCompare::BUILD,
          counts: {
            type: :object,
            properties: {
              newShips: {type: :integer},
              changedShips: {type: :integer},
              vanishedShips: {type: :integer},
              newComponents: {type: :integer},
              changedComponents: {type: :integer},
              newEquipment: {type: :integer},
              changedEquipment: {type: :integer},
              vanishedEquipment: {type: :integer}
            },
            additionalProperties: false,
            required: %w[newShips changedShips vanishedShips newComponents changedComponents newEquipment
              changedEquipment vanishedEquipment]
          },
          newShips: {type: :array, items: SHIP},
          # The ships the most recent patch with any brought, for a patch that
          # brought none. Only ships arriving since builds were kept carry one.
          latestArrivals: {type: :array, items: SHIP},
          latestArrivalsVersion: {type: [:string, :null]},
          shipChanges: {
            type: :array,
            items: {
              type: :object,
              properties: {
                model: SHIP,
                fields: {type: :array, items: FIELD}
              },
              additionalProperties: false,
              required: %w[model fields]
            }
          },
          itemChanges: {
            type: :array,
            items: {
              type: :object,
              properties: {
                kind: {type: :string, enum: %w[components equipment]},
                id: {type: :string, format: :uuid},
                name: {type: [:string, :null]},
                slug: {type: [:string, :null]},
                fields: {type: :array, items: FIELD}
              },
              additionalProperties: false,
              required: %w[kind id fields]
            }
          }
        },
        additionalProperties: false,
        required: %w[from to counts newShips latestArrivals shipChanges itemChanges]
      })
    end
  end
end
