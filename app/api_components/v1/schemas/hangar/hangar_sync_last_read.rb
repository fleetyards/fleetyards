# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class HangarSyncLastRead
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            finishedAt: {type: [:string, :null], format: "date-time"},
            pages: {type: [:integer, :null]},
            total: {type: :integer},
            counts: {
              type: :object,
              properties: %w[ship component upgrade skin flair equipment ccu extra].index_with { {type: :integer} },
              additionalProperties: false,
              required: %w[ship component upgrade skin flair equipment ccu extra]
            }
          },
          additionalProperties: false,
          required: %w[total counts]
        })
      end
    end
  end
end
