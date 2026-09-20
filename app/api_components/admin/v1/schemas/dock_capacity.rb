# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class DockCapacity
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            dockId: {type: :string, format: :uuid},
            ladder: Enums::DockCapacityLadderEnum,
            size: {type: :string},
            sizeLabel: {type: :string},
            quantity: {type: :integer},
            # The entry a berth's label is rendered from. One per dock at most.
            display: {type: :boolean},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id dockId ladder size sizeLabel quantity display createdAt updatedAt]
        })
      end
    end
  end
end
