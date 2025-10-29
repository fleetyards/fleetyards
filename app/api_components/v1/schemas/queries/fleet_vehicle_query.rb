# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class FleetVehicleQuery
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            beamGteq: {type: :number},
            beamLteq: {type: :number},
            classificationIn: {type: :array, items: {type: :string}},
            focusIn: {type: :array, items: {type: :string}},
            heightGteq: {type: :number},
            heightLteq: {type: :number},
            lengthGteq: {type: :number},
            lengthLteq: {type: :number},
            manufacturerIn: {type: :array, items: {type: :string}},
            onSaleEq: {type: :boolean},
            pledgePriceGteq: {type: :number},
            pledgePriceLteq: {type: :number},
            pledgePriceIn: {type: :array, items: {type: :number}},
            priceGteq: {type: :number},
            priceLteq: {type: :number},
            priceIn: {type: :array, items: {type: :number}},
            productionStatusIn: {type: :array, items: {type: :string}},
            searchCont: {type: :string},
            sizeIn: {type: :array, items: {type: :string}},
            modelNameCont: {type: :string},
            modelNameOrModelDescriptionCont: {type: :string},
            loanerEq: {type: :boolean},
            memberIn: {type: :array, items: {type: :string}},
            sorts: {anyOf: [{
              type: :array, items: {"$ref": "#/components/schemas/FleetVehicleSortEnum"}
            }, {
              "$ref": "#/components/schemas/FleetVehicleSortEnum"
            }]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
