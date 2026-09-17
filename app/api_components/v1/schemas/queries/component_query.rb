# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class ComponentQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            nameCont: {type: :string},
            descriptionCont: {type: :string},
            manufacturerNameCont: {type: :string},
            idIn: {type: :array, items: {type: :string, format: :uuid}},
            nameIn: {type: :array, items: {type: :string}},
            manufacturerSlugIn: {type: :array, items: {type: :string}},

            # Deprecated with the filter endpoints that feed them: no component
            # in the current build carries `itemType` or `class`, so neither can
            # match anything. Still accepted so a client asking for nothing is
            # not silently handed everything.
            itemTypeIn: {type: :array, items: {type: :string}, deprecated: true},
            componentClassIn: {type: :array, items: {type: :string}, deprecated: true},
            categoryIn: {type: :array, items: {type: :string}},
            componentSubTypeIn: {type: :array, items: {type: :string}},
            currentVersion: {type: :boolean},
            hiddenEq: {type: :boolean},
            s: {type: :string, enum: ::Component::ALLOWED_SORTING_PARAMS},
            sorts: {type: :array, items: {type: :string, enum: ::Component::ALLOWED_SORTING_PARAMS}}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
