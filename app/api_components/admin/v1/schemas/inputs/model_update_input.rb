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
              name: {type: :string, nullable: true},
              description: {type: :string, nullable: true},
              hidden: {type: :boolean},
              active: {type: :boolean},
              ground: {type: :boolean},
              mass: {type: :number, nullable: true},
              minCrew: {type: :integer, nullable: true},
              maxCrew: {type: :integer, nullable: true},
              scmSpeed: {type: :number, nullable: true},
              scmSpeedBoosted: {type: :number, nullable: true},
              maxSpeed: {type: :number, nullable: true},
              reverseSpeedBoosted: {type: :number, nullable: true},
              yaw: {type: :number, nullable: true},
              yawBoosted: {type: :number, nullable: true},
              pitch: {type: :number, nullable: true},
              pitchBoosted: {type: :number, nullable: true},
              roll: {type: :number, nullable: true},
              rollBoosted: {type: :number, nullable: true},
              scKey: {type: :string, nullable: true},
              erkulIdentifier: {type: :string, nullable: true},
              manufacturerId: {type: :string, format: :uuid},
              rsiId: {type: :integer, nullable: true},
              baseModelId: {type: :string, format: :uuid},
              productionStatus: {type: :string},
              productionNote: {type: :string, nullable: true},
              classification: {type: :string},
              focus: {type: :string},
              size: {type: :string},
              dockSize: {type: :string},
              length: {type: :number, nullable: true},
              beam: {type: :number, nullable: true},
              height: {type: :number, nullable: true},
              fleetchartOffsetLength: {type: :number, nullable: true},
              fleetchartOffsetBeam: {type: :number, nullable: true},
              onSale: {type: :boolean},
              playerOwnable: {type: :boolean},
              storeUrl: {type: :string, nullable: true},
              salesPageUrl: {type: :string, nullable: true},
              price: {type: :number, nullable: true},
              pledgePrice: {type: :number, nullable: true},
              cargo: {type: :number, nullable: true},
              cargoHolds: {type: :string, nullable: true},
              hydrogenFuelTankSize: {type: :number, nullable: true},
              hydrogenFuelTanks: {type: :string, nullable: true},
              quantumFuelTankSize: {type: :number, nullable: true},
              quantumFuelTanks: {type: :string, nullable: true},
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
