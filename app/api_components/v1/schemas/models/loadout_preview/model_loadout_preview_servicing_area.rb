# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module LoadoutPreview
        # A box where the ship services the ships landed in it, in the hull
        # holo's frame. `name` is what an admin called it, or null; `index`
        # numbers it as the ship's page does.
        class ModelLoadoutPreviewServicingArea
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              key: {type: :string},
              name: {type: [:string, :null]},
              index: {type: :integer},
              position: {type: :array, items: {type: :number}, minItems: 3, maxItems: 3, description: "The box's centre"},
              rotation: {type: :array, items: {type: :number}, minItems: 4, maxItems: 4, description: "Quaternion x, y, z, w"},
              size: {type: :array, items: {type: :number}, minItems: 3, maxItems: 3, description: "Along the box's own x, up and depth axes"}
            },
            additionalProperties: false,
            required: %w[key name index position rotation size]
          })
        end
      end
    end
  end
end
