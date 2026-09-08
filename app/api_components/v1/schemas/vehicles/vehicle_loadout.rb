# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class VehicleLoadout
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            active: {type: :boolean},
            url: {type: :string},
            urlSource: {type: :string},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id active url createdAt updatedAt]
        })
      end
    end
  end
end
