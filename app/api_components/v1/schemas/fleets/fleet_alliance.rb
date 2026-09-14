# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      # An alliance or a request, from the acting fleet's side. `fleet` is
      # always the *other* fleet.
      class FleetAlliance
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            state: ::V1::Schemas::Enums::RelationshipStateEnum,
            direction: ::V1::Schemas::Enums::RelationshipDirectionEnum,
            fleet: ::V1::Schemas::Fleets::AlliedFleet,
            acceptedAt: {type: [:string, :null], format: "date-time"},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id state direction fleet createdAt updatedAt]
        })
      end
    end
  end
end
