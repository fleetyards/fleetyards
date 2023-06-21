# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class ModelQuery
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            beamGteq: {type: :number, nullable: true},
            beamLteq: {type: :number, nullable: true},
            classificationIn: {type: :array, items: {type: :string}, nullable: true},
            descriptionCont: {type: :string, nullable: true},
            focus_in: {type: :array, items: {type: :string}, nullable: true},
            heightGteq: {type: :number, nullable: true},
            heightLteq: {type: :number, nullable: true},
            idIn: {type: :array, items: {type: :string}, nullable: true},
            idNotIn: {type: :array, items: {type: :string}, nullable: true},
            lengthGteq: {type: :number, nullable: true},
            lengthLteq: {type: :number, nullable: true},
            manufacturerIn: {type: :array, items: {type: :string}, nullable: true},
            nameCont: {type: :string, nullable: true},
            nameIn: {type: :array, items: {type: :string}, nullable: true},
            nameOrDescriptionCont: {type: :string, nullable: true},
            onSaleEq: {type: :boolean, nullable: true},
            pledgePriceGteq: {type: :number, nullable: true},
            pledgePriceLteq: {type: :number, nullable: true},
            pledge_price_in: {type: :array, items: {type: :number}, nullable: true},
            priceGteq: {type: :number, nullable: true},
            priceLteq: {type: :number, nullable: true},
            price_in: {type: :array, items: {type: :number}, nullable: true},
            production_status_in: {type: :array, items: {type: :string}, nullable: true},
            searchCont: {type: :string, nullable: true},
            size_in: {type: :array, items: {type: :string}, nullable: true},
            sorts: {oneOf: [{
              type: :array, items: {type: :string}
            }, {
              type: :string
            }], nullable: true},
            willItFit: {type: :string, format: :uuid, nullable: true}
          }
        })
      end
    end
  end
end
