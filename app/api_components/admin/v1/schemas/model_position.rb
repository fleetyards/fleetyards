# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class ModelPosition
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            positionType: {type: :string},
            source: {type: :string},
            position: {type: :integer},
            hardpointId: {type: :string, format: :uuid, nullable: true},
            modelId: {type: :string, format: :uuid},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id name positionType source position modelId createdAt updatedAt]
        })
      end
    end
  end
end
