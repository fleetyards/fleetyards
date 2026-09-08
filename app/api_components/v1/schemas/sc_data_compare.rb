# frozen_string_literal: true

module V1
  module Schemas
    # What two builds say differently, per catalogue.
    #
    # `vanished` means the newer build has no row for the record, not that
    # anything was deleted: a catalogue row the export drops keeps its row and
    # loses its build.
    #
    # `changed` names the fields that differ rather than pre-digesting them, so a
    # reader can pick what it cares about — a rename is a change on `name` rather
    # than a category of its own. Prose and serialized shapes are not compared;
    # see `ScData::BuildCompare` for the measurements behind that.
    class ScDataCompare
      include OpenapiRuby::Components::Base

      BUILD = {
        type: :object,
        properties: {
          environment: {type: :string},
          version: {type: :string}
        },
        additionalProperties: false,
        required: %w[environment version]
      }.freeze

      # A record identified and named. `name` is nullable because not every
      # catalogue's build row carries one, and absent rather than blank is the
      # honest answer when it does not.
      ENTRY = {
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: [:string, :null]}
        },
        additionalProperties: false,
        required: %w[id]
      }.freeze

      CATALOGUE = {
        type: :object,
        properties: {
          # False when one side has no rows for this catalogue at all -- it was
          # not recorded for that build, rather than everything having appeared.
          # The lists are empty when it is false.
          recorded: {type: :boolean},
          counts: {
            type: :object,
            properties: {
              appeared: {type: :integer},
              vanished: {type: :integer},
              changed: {type: :integer}
            },
            additionalProperties: false,
            required: %w[appeared vanished changed]
          },
          appeared: {type: :array, items: ENTRY},
          vanished: {type: :array, items: ENTRY},
          changed: {
            type: :array,
            items: {
              type: :object,
              properties: {
                id: {type: :string, format: :uuid},
                name: {type: [:string, :null]},
                fields: {type: :array, items: {type: :string}}
              },
              additionalProperties: false,
              required: %w[id fields]
            }
          }
        },
        additionalProperties: false,
        required: %w[recorded counts appeared vanished changed]
      }.freeze

      schema({
        type: :object,
        properties: {
          from: BUILD,
          to: BUILD,
          catalogues: {
            type: :object,
            properties: {
              components: CATALOGUE,
              equipment: CATALOGUE,
              commodities: CATALOGUE,
              models: CATALOGUE
            },
            additionalProperties: false,
            required: %w[components equipment commodities models]
          }
        },
        additionalProperties: false,
        required: %w[from to catalogues]
      })
    end
  end
end
