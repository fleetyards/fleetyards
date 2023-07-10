# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class HangarQuery
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            beamGteq: {type: :number},
            beamLteq: {type: :number},
            classificationIn: {type: :array, items: {type: :string}},
            descriptionCont: {type: :string},
            focusIn: {type: :array, items: {type: :string}},
            heightGteq: {type: :number},
            heightLteq: {type: :number},
            idIn: {type: :array, items: {type: :string}},
            idNotIn: {type: :array, items: {type: :string}},
            lengthGteq: {type: :number},
            lengthLteq: {type: :number},
            manufacturerIn: {type: :array, items: {type: :string}},
            nameCont: {type: :string},
            nameIn: {type: :array, items: {type: :string}},
            nameOrDescriptionCont: {type: :string},
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
            modelNameOrModelDescriptionCont: {type: :string},
            publicEq: {type: :boolean},
            loanerEq: {type: :boolean},
            boughtViaEq: {"$ref": "#/components/schemas/BoughtViaEnum"},
            hangarGroupsIn: {type: :array, items: {type: :string}},
            hangarGroupsNotIn: {type: :array, items: {type: :string}},
            willItFit: {type: :string, format: :uuid}
          },
          additionalProperties: false
        })
      end
    end
  end
end
