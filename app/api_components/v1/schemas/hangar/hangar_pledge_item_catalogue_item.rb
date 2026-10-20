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
            size: {type: :string},
            listed: {type: :boolean, description: "False for an item the catalogue leaves out, whose page would 404"}
          },
          additionalProperties: false,
          required: %w[itemType id name listed]
        })
      end
    end
  end
end
