# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ModelUpdateInput
          include SchemaConcern

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
              onSale: {type: :boolean},
              storeUrl: {type: :string},
              salesPageUrl: {type: :string},
              price: {type: :number},
              pledgePrice: {type: :number},
              lastPledgePrice: {type: :number},
              cargo: {type: :number},
              cargoHolds: {type: :string},
              hydrogenFuelTankSize: {type: :number},
              hydrogenFuelTanks: {type: :string},
              quantumFuelTankSize: {type: :number},
              quantumFuelTanks: {type: :string},
              storeImageNew: {type: :string}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
