# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Dock
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            dockType: Enums::DockTypeEnum,
            dockTypeLabel: {type: :string},
            shipSize: Enums::DockShipSizeEnum,
            shipSizeLabel: {type: :string},
            # Nullable both ways: a berth nobody has looked at has no access
            # recorded, and the label is derived from it.
            access: {oneOf: [Enums::DockAccessEnum, {type: :null}]},
            accessLabel: {type: [:string, :null]},
            group: {type: :string},
            length: {type: :number},
            beam: {type: :number},
            height: {type: :number},
            minShipSize: {type: :integer},
            maxShipSize: {type: :integer},
            # What the berth is built for, and how many at once. Alternatives
            # rather than a sum -- see DockCapacity.
            capacities: {type: :array, items: DockCapacity},
            parentId: {type: :string, format: :uuid},
            parentType: {type: :string},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[
            id dockType dockTypeLabel shipSize shipSizeLabel capacities parentId parentType
            createdAt updatedAt
          ]
        })
      end
    end
  end
end
