# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      # The live `hardpoints` table as the admin sees it: a superset of the
      # public `Hardpoint`, with the parent, the tag lists, and the two answers
      # the admin UI needs in order to decide what to offer -- whether the slot
      # is editable and whether the build still describes it.
      #
      # Named `AdminHardpoint` rather than `Hardpoint` because the shared
      # component of that name is emitted into this document too, and two
      # definitions cannot share one name.
      class AdminHardpoint
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            parentId: {type: :string, format: :uuid},
            parentType: {type: :string},
            source: ::Shared::V1::Schemas::Enums::HardpointSourceEnum,

            # The loader owns the game-files half and rewrites it on every load,
            # so only the curated half may be changed. The frontend reads this
            # rather than deriving it from `source`, so the rule lives in one
            # place.
            editable: {type: :boolean},

            # Not in the build in force. Only ever true for the game-files half.
            retired: {type: :boolean},

            group: ::Shared::V1::Schemas::Enums::HardpointGroupEnum,
            category: ::Shared::V1::Schemas::Enums::HardpointCategoryEnum,
            groupKey: {type: :string},
            matrixKey: {type: :string},
            minSize: {type: :integer},
            maxSize: {type: :integer},
            types: {type: :array, items: {type: :string}},
            portTags: {type: :array, items: {type: :string}},
            requiredTags: {type: :array, items: {type: :string}},
            flags: {type: :array, items: {type: :string}},
            details: {type: :string},
            component: {"$ref": "#/components/schemas/Component"},
            hardpoints: {type: :array, items: {"$ref": "#/components/schemas/AdminHardpoint"}},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id name source editable retired createdAt updatedAt]
        })
      end
    end
  end
end
