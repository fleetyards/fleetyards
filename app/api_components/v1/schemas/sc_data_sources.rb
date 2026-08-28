# frozen_string_literal: true

module V1
  module Schemas
    # The builds a reader may be pointed at, which is what the source switch is
    # built from. Never empty: the default is configured, and a catalogue has to
    # carry builds for it or nothing would read at all.
    class ScDataSources
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          items: {
            type: :array,
            items: {
              type: :object,
              properties: {
                environment: {type: :string},
                version: {type: :string},

                # What a request that names no source gets.
                default: {type: :boolean}
              },
              additionalProperties: false,
              required: %w[environment version default]
            }
          }
        },
        additionalProperties: false,
        required: %w[items]
      })
    end
  end
end
