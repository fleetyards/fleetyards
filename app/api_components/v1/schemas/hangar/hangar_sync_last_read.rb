# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class HangarSyncLastRead
        include OpenapiRuby::Components::Base

        COUNT_KEYS = ::Imports::HangarSync::READ_KINDS.map { |kind| kind.camelize(:lower) }.freeze

        schema({
          type: :object,
          properties: {
            finishedAt: {type: [:string, :null], format: "date-time"},
            pages: {type: [:integer, :null]},
            total: {type: :integer},
            counts: {
              type: :object,
              properties: COUNT_KEYS.index_with { {type: :integer} },
              additionalProperties: false,
              required: COUNT_KEYS
            }
          },
          additionalProperties: false,
          required: %w[total counts]
        })
      end
    end
  end
end
