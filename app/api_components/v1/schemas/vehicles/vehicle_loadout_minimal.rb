# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class VehicleLoadoutMinimal
        include OpenapiRuby::Components::Base

        # "Minimal" is about the omitted hardpoints: api/v1/vehicle_loadouts/base
        # renders every other field it has, including the shared timestamps, so
        # those belong here too.
        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            active: {type: :boolean},
            kind: ::V1::Schemas::Enums::VehicleLoadoutKindEnum,
            url: {type: :string},
            urlSource: {type: :string},
            items: {type: :array, items: ::V1::Schemas::Vehicles::VehicleLoadoutItem},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id name active kind items createdAt updatedAt]
        })
      end
    end
  end
end
