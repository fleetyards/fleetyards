# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class FleetInventory
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            fleetId: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},
            description: {type: [:string, :null]},
            location: {type: [:string, :null]},
            visibility: ::Admin::V1::Schemas::Enums::FleetInventoryVisibilityEnum,
            managerId: {type: [:string, :null], format: :uuid},
            managerUsername: {type: [:string, :null]},
            itemsCount: {type: :integer},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id fleetId name slug visibility itemsCount createdAt updatedAt]
        })
      end
    end
  end
end
