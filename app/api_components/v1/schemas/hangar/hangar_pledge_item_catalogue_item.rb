# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class HangarPledgeItemCatalogueItem
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          description: "The catalogue item a ship component or piece of FPS gear was matched to",
          properties: {
            itemType: {type: :string, enum: %w[Component Equipment]},
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},
            category: {type: :string, description: "The component's category, or the equipment's type"},
            size: {type: :string}
          },
          additionalProperties: false,
          required: %w[itemType id name]
        })
      end
    end
  end
end
