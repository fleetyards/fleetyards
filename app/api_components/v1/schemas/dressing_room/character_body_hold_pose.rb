# frozen_string_literal: true

module V1
  module Schemas
    module DressingRoom
      class CharacterBodyHoldPose
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            weapon: {type: :string, enum: %w[rifle pistol], description: "The kind of weapon the clip holds"},
            armorWeight: {
              type: [:string, :null],
              description: "The worn core's armour weight as its subType spells it, e.g. Heavy; null for no core"
            },
            clip: {type: :string, description: "The clip that holds the weapon lowered, in the body's animations file"}
          },
          additionalProperties: false,
          required: %w[weapon armorWeight clip]
        })
      end
    end
  end
end
