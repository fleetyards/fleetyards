# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class Blueprint
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},

            # A blueprint has no name of its own -- 1606 of the 1607 records in
            # the current build carry a placeholder -- so this is the name of
            # whatever the recipe makes. Null for the four whose output is in
            # no catalogue and the one whose entity class is in no file.
            name: {type: [:string, :null]},
            slug: {type: :string},
            scKey: {type: :string},
            scRef: {type: :string},

            # Seconds.
            craftTime: {type: [:integer, :null]},

            # How many of the slots a single craft fills, which is not always
            # all of them.
            slotCount: {type: [:integer, :null]},

            retired: {type: :boolean},

            # Whether the reader holds this recipe. False rather than absent on
            # an anonymous read -- the catalogue is public, so "not signed in"
            # and "signed in without it" are the same answer here.
            #
            # Not required, though the catalogue always sends it: the admin
            # blueprint component inherits this one, and an admin reading the
            # catalogue is not being asked what they personally hold.
            owned: {type: :boolean},

            # Said outright rather than left to an empty `sources`: the export
            # says nothing about where 901 of the 1607 recipes come from, and
            # an empty array reads as a gap in our data rather than in the
            # game's.
            sourceUnknown: {type: :boolean},

            # A component of its own rather than an inline object: Orval names
            # an anonymous nested shape after its owner and reproduces it once
            # per owner.
            craftable: {
              anyOf: [::Shared::V1::Schemas::BlueprintCraftable, {type: :null}]
            },

            # What the recipe consumes, named. On the list as well as the
            # detail: "what does this eat" is a question the list itself has
            # to answer.
            materials: {type: :array, items: ::Shared::V1::Schemas::BlueprintCostCommodity},

            # Detail responses only -- a list omits both rather than paying
            # three association hits per row, which is why neither is required.
            costSlots: {type: :array, items: ::Shared::V1::Schemas::BlueprintCostSlot},
            sources: {type: :array, items: ::Shared::V1::Schemas::BlueprintSource},

            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id slug scKey scRef retired sourceUnknown createdAt updatedAt]
        })
      end
    end
  end
end
