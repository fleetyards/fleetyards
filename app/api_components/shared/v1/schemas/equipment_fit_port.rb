# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class EquipmentFitPort
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          description: "A port the item offers to armour pieces or weapons",
          properties: {
            name: {type: :string},
            types: {type: :array, items: ::Shared::V1::Schemas::EquipmentFitPortType},
            minSize: {type: :integer},
            maxSize: {type: :integer},
            portTags: {type: :array, items: {type: :string}},
            requiredTags: {type: :array, items: {type: :string}, description: "Tags an item needs to go in it; a leading $ is not part of the tag"},
            bone: {type: :string, description: "The bone of the piece's rig an item in this port hangs from"},
            itemHelper: {type: :string, description: "The helper on the item that meets that bone"}
          },
          additionalProperties: false,
          required: %w[name types minSize maxSize]
        })
      end
    end
  end
end
