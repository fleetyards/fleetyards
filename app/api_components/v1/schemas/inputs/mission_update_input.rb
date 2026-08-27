# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class MissionUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            title: {type: :string},
            description: {type: [:string, :null]},
            category: ::V1::Schemas::Enums::MissionCategoryEnum,
            scenario: {type: [:string, :null]},
            coverImagePreset: {type: [:string, :null]},
            coverImage: {type: [:string, :null]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
