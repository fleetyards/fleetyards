# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class Component
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},
            scKey: {type: :string},
            scRef: {type: :string},

            hidden: {type: :boolean},
            retired: {type: :boolean},

            category: {type: :string},
            type: ::Shared::V1::Schemas::Enums::ComponentTypeEnum,
            subType: {type: :string},

            description: {type: :string},

            # A port and the item that fits it name a shared tag. `tags` -- the
            # item's own -- is absent until the parser stops double-encoding it.
            requiredTags: {type: :array, items: {type: :string}},

            # Left as the string main documents. It is an object really, but
            # nothing has ever emitted it, and correcting the type registers as
            # a breaking change on every path `Component` nests under -- which
            # oasdiff reports under a *different* path on each run, so no
            # ignore list can match it reliably (measured: 4 of 6 identical
            # runs failed). It comes back with the parser cleanup that #5002
            # needs, as one deliberate change rather than a flaky check.
            inventoryConsumption: {type: :string},

            grade: {type: :string},
            gradeLabel: {type: :string},
            size: {type: :string},
            class: ::Shared::V1::Schemas::Enums::ComponentClassEnum,
            itemClass: ::Shared::V1::Schemas::Enums::ComponentItemClassEnum,
            itemClassLabel: {type: :string},

            availability: Shared::V1::Schemas::ItemAvailability,

            manufacturer: {"$ref": "#/components/schemas/Manufacturer"},

            media: Shared::V1::Schemas::StoreImageMedia,

            typeData: {
              anyOf: [
                ::Shared::V1::Schemas::ComponentQuantumDrive,
                ::Shared::V1::Schemas::ComponentJumpDrive,
                ::Shared::V1::Schemas::ComponentArmor,
                ::Shared::V1::Schemas::CargoHold,
                ::Shared::V1::Schemas::FuelTank,
                ::Shared::V1::Schemas::ComponentThruster,
                ::Shared::V1::Schemas::ComponentWeapon,
                ::Shared::V1::Schemas::ComponentTractorBeam,
                ::Shared::V1::Schemas::ComponentShield,
                ::Shared::V1::Schemas::ComponentCooler,
                ::Shared::V1::Schemas::ComponentRadar,
                ::Shared::V1::Schemas::ComponentController,
                ::Shared::V1::Schemas::ComponentPowerPlant
              ]
            },

            # Detail responses only -- a list omits it rather than paying an
            # association hit per row, which is why it is not required.
            hardpoints: {type: :array, items: ::Shared::V1::Schemas::Hardpoint},

            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id name slug hidden retired availability media createdAt updatedAt]
        })
      end
    end
  end
end
