# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ModelUpdateInput
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              name: {type: :string},
              description: {type: :string},
              hidden: {type: :boolean},
              active: {type: :boolean},
              ground: {type: :boolean},
              mass: {type: :number},
              minCrew: {type: :integer},
              maxCrew: {type: :integer},
              scmSpeed: {type: :number},
              scmSpeedBoosted: {type: :number},
              maxSpeed: {type: :number},
              reverseSpeedBoosted: {type: :number},
              yaw: {type: :number},
              yawBoosted: {type: :number},
              pitch: {type: :number},
              pitchBoosted: {type: :number},
              roll: {type: :number},
              rollBoosted: {type: :number},
              scIdentifier: {type: :string},
              erkulIdentifier: {type: :string},
              manufacturerId: {type: :string, format: :uuid},
              rsiId: {type: :integer},
              baseModelId: {type: :string, format: :uuid},
              productionStatus: {type: :string},
              productionNote: {type: :string},
              classification: {type: :string},
              focus: {type: :string},
              size: {type: :string},
              dockSize: {type: :string},
              length: {type: :number},
              beam: {type: :number},
              height: {type: :number},
              fleetchartOffsetLength: {type: :number},
              fleetchartOffsetBeam: {type: :number},
              onSale: {type: :boolean},
              storeUrl: {type: :string},
              salesPageUrl: {type: :string},
              price: {type: :number},
              pledgePrice: {type: :number},
              cargo: {type: :number},
              cargoHolds: {type: :string},
              hydrogenFuelTankSize: {type: :number},
              hydrogenFuelTanks: {type: :string},
              quantumFuelTankSize: {type: :number},
              quantumFuelTanks: {type: :string},
              newStoreImage: {type: :string, nullable: true},
              newFleetchartImage: {type: :string, nullable: true},
              newTopView: {type: :string, nullable: true},
              newSideView: {type: :string, nullable: true},
              newFrontView: {type: :string, nullable: true},
              newAngledView: {type: :string, nullable: true},
              newTopViewColored: {type: :string, nullable: true},
              newSideViewColored: {type: :string, nullable: true},
              newFrontViewColored: {type: :string, nullable: true},
              newAngledViewColored: {type: :string, nullable: true},
              newBrochure: {type: :string, nullable: true},
              newHolo: {type: :string, nullable: true}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
