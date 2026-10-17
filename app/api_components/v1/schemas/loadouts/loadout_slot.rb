# frozen_string_literal: true

module V1
  module Schemas
    module Loadouts
      class LoadoutSlot
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string, description: "Hardpoint name; a slot path joins these from the hull down with /"},
            hardpointId: {type: :string, format: :uuid, description: "The port whose rules decide what fits"},
            category: ::Shared::V1::Schemas::Enums::HardpointCategoryEnum,
            minSize: {type: :integer},
            maxSize: {type: :integer},
            types: {type: :array, items: {type: :string}},
            editable: {type: :boolean, description: "False where the game locks the part in place"},
            swappable: {type: :boolean, description: "Whether anything but the stock part fits"},
            stock: ::V1::Schemas::Loadouts::LoadoutComponentRef,
            fitted: ::V1::Schemas::Loadouts::LoadoutComponentRef,
            slots: {type: :array, items: ::V1::Schemas::Loadouts::LoadoutSlot}
          },
          additionalProperties: false,
          required: %w[name hardpointId types editable slots]
        })
      end
    end
  end
end
