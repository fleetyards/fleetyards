# frozen_string_literal: true

module V1
  module Schemas
    class FactionLadder
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          key: {type: :string},
          name: {type: :string},
          ceiling: {type: [:integer, :null]},
          ranks: {type: :array, items: ::V1::Schemas::FactionRank},

          # What completing this faction's released missions adds to this
          # ladder. Zero missions and null amounts where none pay into it.
          missionCount: {type: :integer},
          minAward: {type: [:integer, :null]},
          maxAward: {type: [:integer, :null]}
        },
        additionalProperties: false,
        required: %w[key name ranks missionCount]
      })
    end
  end
end
