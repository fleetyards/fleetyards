# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class MissionUpdateInput
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            title: {type: :string},
            description: {type: :string, nullable: true},
            category: {
              type: :string,
              enum: V1::Schemas::Fleets::Missions::Mission::CATEGORIES
            },
            scenario: {type: :string, nullable: true},
            coverImagePreset: {type: :string, nullable: true},
            coverImage: {type: :string, nullable: true},
            archivedAt: {type: :string, format: "date-time", nullable: true}
          },
          additionalProperties: false
        })
      end
    end
  end
end
