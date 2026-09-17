# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # What a recipe makes, as much of it as a catalogue row needs: enough to
      # name the thing and link to it, without pulling in the whole component,
      # equipment or commodity payload.
      class BlueprintCraftable
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            type: ::Shared::V1::Schemas::Enums::BlueprintCraftableTypeEnum,
            id: {type: :string, format: :uuid},

            # 5 of the 1607 recipes in the current build point at something the
            # catalogues cannot name.
            name: {type: [:string, :null]},
            slug: {type: :string}
          },
          additionalProperties: false,
          required: %w[type id slug]
        })
      end
    end
  end
end
