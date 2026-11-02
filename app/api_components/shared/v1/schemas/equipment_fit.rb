# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class EquipmentFit
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            type: {type: :string, description: "The game's item type, e.g. Char_Armor_Torso"},
            tags: {type: :array, items: {type: :string}},
            requiredTags: {type: :array, items: {type: :string}, description: "Tags the port it goes in has to offer"},
            ports: {type: :array, items: ::Shared::V1::Schemas::EquipmentFitPort}
          },
          additionalProperties: false,
          required: %w[type]
        })
      end
    end
  end
end
