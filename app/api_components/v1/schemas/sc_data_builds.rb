# frozen_string_literal: true

module V1
  module Schemas
    # Every build there is a row for, newest first.
    #
    # The same shape as `ScDataSources` and a different list: that one is what a
    # reader may be pointed *at*, which deliberately hides everything behind the
    # default. A comparison needs exactly what it hides, and it reaches back past
    # the config, which names one version per environment.
    class ScDataBuilds
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
