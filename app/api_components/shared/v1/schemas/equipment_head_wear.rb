# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class EquipmentHeadWear
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          description: "What a hat, helmet, mask or hood does to a character's hair, beard and head while worn",
          properties: {
            type: {type: :string, description: "The game's item type, e.g. Char_Armor_Helmet"},
            fit: {type: :string, enum: %w[rigid face_wrap], description: "face_wrap follows the character's face like the hair; rigid keeps its own shape"},
            hairTag: {type: [:string, :null], description: "The hair variant it asks for, e.g. snoopy_cap or hatHair"},
            maskFacialHair: {type: :boolean, description: "Whether it asks beards and stubble for their trimmed variant"},
            addsTags: {type: :array, items: {type: :string}, description: "Further variant tags it pushes onto the character"},
            hiddenParts: {type: :array, items: {type: :string}, description: "The game ports it hides, e.g. Hair_ItemPort"}
          },
          additionalProperties: false,
          required: %w[type fit hairTag maskFacialHair addsTags hiddenParts]
        })
      end
    end
  end
end
