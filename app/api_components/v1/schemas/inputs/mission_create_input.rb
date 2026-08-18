# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class MissionCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            title: {type: :string},
            description: {type: [:string, :null]},
            category: {
              type: :string,
              enum: V1::Schemas::Fleets::Missions::Mission::CATEGORIES
            },
            scenario: {type: [:string, :null]},
            coverImagePreset: {type: [:string, :null]},
            coverImage: {type: [:string, :null]}
          },
          required: %w[title],
          additionalProperties: false
        })
      end
    end
  end
end
