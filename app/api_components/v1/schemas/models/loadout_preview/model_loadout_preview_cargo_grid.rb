# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module LoadoutPreview
        # A cargo grid in the hull holo's frame. A grid with a parent port sits
        # on the module mounted there.
        class ModelLoadoutPreviewCargoGrid
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              name: {type: :string},
              port: {type: [:string, :null]},
              parentPort: {type: [:string, :null]},
              position: {type: :array, items: {type: :number}, minItems: 3, maxItems: 3, description: "The grid's centre"},
              rotation: {type: :array, items: {type: :number}, minItems: 4, maxItems: 4, description: "Quaternion x, y, z, w"},
              size: {type: :array, items: {type: :number}, minItems: 3, maxItems: 3, description: "Metres along the grid's own x, up and depth axes"},
              scu: {type: [:number, :null]},
              stripped: {type: :boolean, description: "The grid belongs to an item left out of the hull holo"}
            },
            additionalProperties: false,
            required: %w[name port parentPort position rotation size scu stripped]
          })
        end
      end
    end
  end
end
