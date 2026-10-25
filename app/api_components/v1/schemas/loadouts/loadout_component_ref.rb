# frozen_string_literal: true

module V1
  module Schemas
    module Loadouts
      # What a loadout slot holds or could hold, without the full catalogue
      # record: a slot tree carries one per slot, and the full record nests its
      # own ports all the way down.
      class LoadoutComponentRef
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},
            category: {type: :string},
            type: ::Shared::V1::Schemas::Enums::ComponentTypeEnum,
            subType: {type: :string},
            size: {type: :string},
            grade: {type: :string},
            gradeLabel: {type: :string},
            itemClass: ::Shared::V1::Schemas::Enums::ComponentItemClassEnum,
            itemClassLabel: {type: :string},
            # What the ship page reads a part's figures from, so a loadout ranks
            # parts on the same ones.
            typeData: ::Shared::V1::Schemas::Component::TYPE_DATA,
            craftable: {type: :boolean, description: "A recipe in the build being served makes it"},
            imageUrl: {type: :string, description: "The store image, or the angled render where there is none, small"}
          },
          additionalProperties: false,
          required: %w[id name]
        })
      end
    end
  end
end
