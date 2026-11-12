# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class ModelQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            cargoGteq: {type: :number},
            cargoLteq: {type: :number},
            beamGteq: {type: :number},
            beamLteq: {type: :number},
            classificationIn: {type: :array, items: {type: :string}},
            descriptionCont: {type: :string},
            focusIn: {type: :array, items: {type: :string}},
            stealthEq: {type: :boolean},
            withLandingServices: {type: :array, items: ::Shared::V1::Schemas::Enums::LandingServiceEnum, description: "Ships that give a ship landed on them every one of these services"},
            heightGteq: {type: :number},
            heightLteq: {type: :number},
            idIn: {type: :array, items: {type: :string}},
            idNotIn: {type: :array, items: {type: :string}},
            lengthGteq: {type: :number},
            lengthLteq: {type: :number},
            manufacturerIn: {type: :array, items: {type: :string}},
            nameCont: {type: :string},
            # What one shop sells or rents, by the shop's slug.
            soldAtShop: {type: :string},
            nameEq: {type: :string},
            slugEq: {type: :string},
            nameIn: {type: :array, items: {type: :string}},
            slugIn: {type: :array, items: {type: :string}},
            nameOrDescriptionCont: {type: :string},
            ingameOnlyEq: {type: :boolean},
            onSaleEq: {type: :boolean},
            playerOwnableEq: {type: :boolean},
            hasFleetchartViews: {type: :boolean, description: "Ships a fleetchart can size and draw"},
            ccuTarget: {type: :boolean, description: "Ships RSI sells upgrades into, today or during sales"},
            plannable: {type: :boolean, description: "Ships a hangar plan can get: sold on the store at a price, earned in game, or held or bought back by the signed-in user"},
            pledgePriceGt: {type: :number},
            pledgePriceGteq: {type: :number},
            pledgePriceLteq: {type: :number},
            pledgePriceIn: {type: :array, items: {type: :string}},
            priceGteq: {type: :number},
            priceLteq: {type: :number},
            priceIn: {type: :array, items: {type: :string}},
            productionStatusIn: {type: :array, items: {type: :string}},
            searchCont: {type: :string},
            sizeIn: {type: :array, items: {type: :string}},
            willItFit: {type: :string},
            withCargo: {type: :boolean},
            withCargoGrids: {type: :boolean},
            withTexturedHolo: {type: :boolean},
            inHangar: {type: :boolean},
            onWishlist: {type: :boolean},
            inGameEq: {type: :boolean},
            s: {anyOf: [{
              type: :array, items: ::Shared::V1::Schemas::Sorts::ModelSortEnum
            }, ::Shared::V1::Schemas::Sorts::ModelSortEnum]},
            sorts: {anyOf: [{
              type: :array, items: ::Shared::V1::Schemas::Sorts::ModelSortEnum
            }, ::Shared::V1::Schemas::Sorts::ModelSortEnum]}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
