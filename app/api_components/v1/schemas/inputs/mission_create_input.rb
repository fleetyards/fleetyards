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
            description: {type: :string},
            category: {
              type: :string,
              enum: V1::Schemas::Fleets::Missions::Mission::CATEGORIES
            },
            scenario: {type: :string},
            coverImagePreset: {type: :string},
            coverImage: {type: :string}
          },
          required: %w[title],
          additionalProperties: false
        })
      end
    end
  end
end
