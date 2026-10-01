# frozen_string_literal: true

module V1
  module Schemas
    module Models
      # One ship's armor, shields and hull health, without the rest of its
      # loadout. `armor` is left out for a ship whose build installs none.
      class ModelDefense
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},
            size: {type: :string},
            manufacturerCode: {type: :string},
            hullHealth: {type: :number},
            armor: ModelDefenseArmor,
            shields: {type: :array, items: ModelDefenseShield}
          },
          additionalProperties: false,
          required: %w[id name slug shields]
        })
      end
    end
  end
end
