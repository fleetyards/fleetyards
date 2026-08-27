# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class FleetVehicleQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            beamGteq: {type: :number},
            beamLteq: {type: :number},
            classificationIn: {type: :array, items: {type: :string}},
            classificationNotIn: {type: :array, items: {type: :string}},
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
            modelSlugIn: {type: :array, items: {type: :string}},
            modelNameCont: {type: :string},
            modelNameOrModelDescriptionCont: {type: :string},
            loanerEq: ::Shared::V1::Schemas::Enums::LoanerFilterEnum,
            memberIn: {type: :array, items: {type: :string}},
            s: {anyOf: [{
              type: :array, items: ::V1::Schemas::Sorts::FleetVehicleSortEnum
            }, ::V1::Schemas::Sorts::FleetVehicleSortEnum]},
            sorts: {anyOf: [{
              type: :array, items: ::V1::Schemas::Sorts::FleetVehicleSortEnum
            }, ::V1::Schemas::Sorts::FleetVehicleSortEnum]}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
