# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class VehicleLogEntry
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            title: {type: :string},
            body: {type: [:string, :null]},
            loggedAt: {type: :string, format: "date-time"},
            public: {type: :boolean},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id title body loggedAt public createdAt updatedAt]
        })
      end
    end
  end
end
