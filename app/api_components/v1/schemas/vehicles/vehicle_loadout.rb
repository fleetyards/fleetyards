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
            public: {type: :boolean},
            kind: ::V1::Schemas::Enums::VehicleLoadoutKindEnum,
            url: {type: :string},
            urlSource: {type: :string},
            items: {type: :array, items: ::V1::Schemas::Vehicles::VehicleLoadoutItem},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id active public kind items createdAt updatedAt]
        })
      end
    end
  end
end
