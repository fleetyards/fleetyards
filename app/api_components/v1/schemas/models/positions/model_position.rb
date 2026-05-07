# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Positions
        class ModelPosition
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              positionType: {type: :string, enum: %w[pilot copilot turret_gunner engineer gunner loadmaster passenger operator custom]},
              source: {type: :string, enum: %w[sc_data curated]},
              position: {type: :integer},
              createdAt: {type: :string, format: "date-time"},
              updatedAt: {type: :string, format: "date-time"}
            },
            additionalProperties: false,
            required: %w[id name positionType source position createdAt updatedAt]
          })
        end
      end
    end
  end
end
