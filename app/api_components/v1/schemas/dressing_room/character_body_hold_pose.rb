# frozen_string_literal: true

module V1
  module Schemas
    module DressingRoom
      class CharacterBodyHoldPose
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            armorWeight: {
              type: [:string, :null],
              description: "The worn core's armour weight as its subType spells it, e.g. Heavy; null for no core"
            },
            clip: {type: :string, description: "The clip that holds a rifle lowered, in the body's animations file"}
          },
          additionalProperties: false,
          required: %w[armorWeight clip]
        })
      end
    end
  end
end
