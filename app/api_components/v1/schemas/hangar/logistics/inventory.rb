# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Logistics
        # Holder-neutral inventory. A ship inventory has no id, slug or
        # timestamps until something is deposited into it, so everything the
        # database assigns is nullable here.
        class Inventory
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: [:string, :null], format: :uuid},
              name: {type: :string},
              slug: {type: [:string, :null]},
              description: {type: [:string, :null]},
              location: {type: [:string, :null]},
              entriesCount: {type: :integer},
              totalScu: {type: :number},
              totalUnits: {type: :number},
              totalVolumeScu: {type: :number},
              unmeasuredCount: {type: :integer},
              image: ::Shared::V1::Schemas::MediaFile,
              vehicle: ::V1::Schemas::InventoryVehicle,
              createdAt: {type: [:string, :null], format: "date-time"},
              updatedAt: {type: [:string, :null], format: "date-time"}
            },
            additionalProperties: false,
            required: %w[id name entriesCount totalScu totalUnits]
          })
        end
      end
    end
  end
end
