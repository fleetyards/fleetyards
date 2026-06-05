# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ModelUpdateInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              name: {type: [:string, :null]},
              description: {type: [:string, :null]},
              hidden: {type: :boolean},
              active: {type: :boolean},
              inGame: {type: :boolean},
              adiMap: {type: :boolean},
              ground: {type: :boolean},
              mass: {type: [:number, :null]},
              minCrew: {type: [:integer, :null]},
              maxCrew: {type: [:integer, :null]},
              scmSpeed: {type: [:number, :null]},
              scmSpeedBoosted: {type: [:number, :null]},
              maxSpeed: {type: [:number, :null]},
              reverseSpeedBoosted: {type: [:number, :null]},
              yaw: {type: [:number, :null]},
              yawBoosted: {type: [:number, :null]},
              pitch: {type: [:number, :null]},
              pitchBoosted: {type: [:number, :null]},
              roll: {type: [:number, :null]},
              rollBoosted: {type: [:number, :null]},
              scKey: {type: [:string, :null]},
              erkulIdentifier: {type: [:string, :null]},
              manufacturerId: {type: :string, format: :uuid},
              rsiId: {type: [:integer, :null]},
              baseModelId: {type: :string, format: :uuid},
              productionStatus: {type: :string},
              productionNote: {type: [:string, :null]},
              classification: {type: :string},
              focus: {type: :string},
              size: {type: :string},
              dockSize: {type: :string},
              length: {type: [:number, :null]},
              beam: {type: [:number, :null]},
              height: {type: [:number, :null]},
              fleetchartOffsetLength: {type: [:number, :null]},
              fleetchartOffsetBeam: {type: [:number, :null]},
              extendedLength: {type: [:number, :null]},
              extendedBeam: {type: [:number, :null]},
              extendedHeight: {type: [:number, :null]},
              extendedFleetchartOffsetLength: {type: [:number, :null]},
              extendedFleetchartOffsetBeam: {type: [:number, :null]},
              onSale: {type: :boolean},
              playerOwnable: {type: :boolean},
              storeUrl: {type: [:string, :null]},
              salesPageUrl: {type: [:string, :null]},
              price: {type: [:number, :null]},
              pledgePrice: {type: [:number, :null]},
              cargo: {type: [:number, :null]},
              cargoHolds: {type: [:string, :null]},
              hydrogenFuelTankSize: {type: [:number, :null]},
              hydrogenFuelTanks: {type: [:string, :null]},
              quantumFuelTankSize: {type: [:number, :null]},
              quantumFuelTanks: {type: [:string, :null]},
              externalFuelTanks: {type: [:string, :null]},
              refuelBoom: {type: [:string, :null]},
              storeImage: {type: [:string, :null]},
              fleetchartImage: {type: [:string, :null]},
              extendedHolo: {type: [:string, :null]},
              topView: {type: [:string, :null]},
              sideView: {type: [:string, :null]},
              frontView: {type: [:string, :null]},
              angledView: {type: [:string, :null]},
              topViewColored: {type: [:string, :null]},
              sideViewColored: {type: [:string, :null]},
              frontViewColored: {type: [:string, :null]},
              angledViewColored: {type: [:string, :null]},
              extendedTopView: {type: [:string, :null]},
              extendedSideView: {type: [:string, :null]},
              extendedFrontView: {type: [:string, :null]},
              extendedAngledView: {type: [:string, :null]},
              extendedTopViewColored: {type: [:string, :null]},
              extendedSideViewColored: {type: [:string, :null]},
              extendedFrontViewColored: {type: [:string, :null]},
              extendedAngledViewColored: {type: [:string, :null]},
              brochure: {type: [:string, :null]},
              holo: {type: [:string, :null]}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
