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
            craftableTypeEq: ::Shared::V1::Schemas::Enums::BlueprintCraftableTypeEnum,
            craftableTypeIn: {type: :array, items: ::Shared::V1::Schemas::Enums::BlueprintCraftableTypeEnum},

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

            # Which side of the law hands it out, without having to know the
            # orgs by name. Several mean "reachable any of these ways": a pool
            # is often handed out by both sides, so this asks for the union.
            #
            # A list from the start, so there is no scalar spelling beside it
            # the way `consumingCommodity` sits beside its `In` form. Values a
            # source can carry and nothing else -- the nine sources the export
            # leaves unattributed are not askable for here, and
            # `withKnownSource` already answers "nothing hands this out".
            sourceAlignmentIn: {
              type: :array, items: ::Shared::V1::Schemas::Enums::BlueprintSourceAlignmentEnum
            },

            # Recipes that consume a material, by the commodity's slug. Several
            # mean "uses any of these": a recipe has at most four slots, so
            # asking for three at once would almost always ask for nothing.
            consumingCommodity: {type: :string},

            # The list form, named as `craftableTypeIn` is beside
            # `craftableTypeEq`. A second parameter rather than widening the
            # first: `consumingCommodity` shipped in #5013 taking one slug, and
            # every caller written against the published schema keeps working.
            # The two combine, so asking both ways asks for the union.
            consumingCommodityIn: {type: :array, items: {type: :string}},

            # Whether the export says where the recipe comes from at all. Read
            # by the controller rather than applied through ransack, which
            # skips a scope whose value is false and would answer the "no known
            # source" question with the whole catalogue.
            withKnownSource: {type: :boolean},

            # The recipes the reader holds, or the ones they do not. Read by the
            # controller rather than applied through ransack, for the reason
            # `withKnownSource` is: a scope reached through ransack can only
            # ever mean "on", so `owned=false` would return the catalogue.
            #
            # Whose recipes is never a parameter -- it is always the caller's --
            # so an anonymous `owned=true` is an empty list rather than an
            # error.
            owned: {type: :boolean},

            currentVersion: {type: :boolean},
            s: ::V1::Schemas::Enums::BlueprintSortingEnum,
            sorts: {type: :array, items: ::V1::Schemas::Enums::BlueprintSortingEnum}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
