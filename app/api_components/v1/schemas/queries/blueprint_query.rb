# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class BlueprintQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            nameCont: {type: :string},
            idIn: {type: :array, items: {type: :string, format: :uuid}},
            nameIn: {type: :array, items: {type: :string}},

            # Which catalogue the output is in. Filtered on the column rather
            # than through the association: ransack cannot compute the class of
            # a polymorphic one and raises the moment a query touches it.
            craftableTypeEq: {type: :string, enum: %w[Component Equipment Commodity]},
            craftableTypeIn: {type: :array, items: {type: :string, enum: %w[Component Equipment Commodity]}},

            # What makes this exact thing -- the reverse of the `craftable`
            # link, asked from the blueprints side.
            #
            # The reverse relation lives here rather than embedded in each
            # catalogue's detail response, because two of the three have no
            # detail endpoint at all: commodities and equipment are
            # list-only. A page that wants "which recipes make this" asks
            # `/blueprints?q[craftableIdEq]=<id>` and gets the same answer
            # whichever catalogue the thing is in.
            craftableIdEq: {type: :string, format: :uuid},

            # Seconds.
            craftTimeLteq: {type: :integer},
            craftTimeGteq: {type: :integer},

            # The org whose missions hand the recipe out, by name.
            fromOrg: {type: :string},

            # Recipes that consume a material, by the commodity's slug.
            consumingCommodity: {type: :string},

            # Whether the export says where the recipe comes from at all. Read
            # by the controller rather than applied through ransack, which
            # skips a scope whose value is false and would answer the "no known
            # source" question with the whole catalogue.
            withKnownSource: {type: :boolean},

            currentVersion: {type: :boolean},
            s: {type: :string, enum: ::Blueprint::ALLOWED_SORTING_PARAMS},
            sorts: {type: :array, items: {type: :string, enum: ::Blueprint::ALLOWED_SORTING_PARAMS}}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
