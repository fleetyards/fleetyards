# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanSlotFilters
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            description: "What the ships for a slot have to be, in the catalogue's filter terms",
            properties: {
              classificationIn: {type: :array, items: {type: :string}},
              focusIn: {type: :array, items: {type: :string}},
              sizeIn: {type: :array, items: {type: :string}},
              manufacturerIn: {type: :array, items: {type: :string}, description: "Manufacturer slugs"},
              productionStatusIn: {type: :array, items: {type: :string}},
              pledgePriceGteq: {type: :number, minimum: 0},
              pledgePriceLteq: {type: :number, minimum: 0},
              cargoGteq: {type: :number, minimum: 0},
              onSaleEq: {type: :boolean}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
