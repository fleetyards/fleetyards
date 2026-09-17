# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class BlueprintCostOption
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            # "resource" is measured in SCU, "item" in whole pieces.
            type: {type: :string, enum: ::BlueprintCostOption::TYPES},
            quantity: {type: :number, nullable: true},
            minQuality: {type: :integer, nullable: true},

            # The material as the game names it, which answers even where the
            # commodity catalogue has no row for it.
            commodityKey: {type: :string, nullable: true},
            commodity: {
              type: :object,
              nullable: true,
              properties: {
                id: {type: :string, format: :uuid},
                name: {type: :string},
                slug: {type: :string}
              },
              additionalProperties: false,
              required: %w[id name slug]
            }
          },
          additionalProperties: false,
          required: %w[type]
        })
      end
    end
  end
end
