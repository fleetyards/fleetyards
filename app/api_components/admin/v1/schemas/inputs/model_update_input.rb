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
              storeImage: {type: :string, nullable: true},
              fleetchartImage: {type: :string, nullable: true},
              topView: {type: :string, nullable: true},
              sideView: {type: :string, nullable: true},
              frontView: {type: :string, nullable: true},
              angledView: {type: :string, nullable: true},
              topViewColored: {type: :string, nullable: true},
              sideViewColored: {type: :string, nullable: true},
              frontViewColored: {type: :string, nullable: true},
              angledViewColored: {type: :string, nullable: true},
              brochure: {type: :string, nullable: true},
              holo: {type: :string, nullable: true}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
