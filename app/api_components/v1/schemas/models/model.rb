# frozen_string_literal: true

module V1
  module Schemas
    module Models
      class Model
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            scIdentifier: {type: :string},
            name: {type: :string},
            slug: {type: :string},

            availability: {
              type: :object,
              properties: {
                boughtAt: {
                  type: :array,
                  items: {"$ref": "#/components/schemas/ItemPrice"}
                },
                soldAt: {
                  type: :array,
                  items: {"$ref": "#/components/schemas/ItemPrice"}
                },
                rentalAt: {
                  type: :array,
                  items: {"$ref": "#/components/schemas/ItemPrice"}
                }
              },
              additionalProperties: false,
              required: %w[boughtAt soldAt rentalAt]
            },

            brochure: {type: :string},
            classification: {type: :string},
            classificationLabel: {type: :string},

            crew: {
              type: :object,
              properties: {
                max: {type: :integer},
                maxLabel: {type: :string},
                min: {type: :integer},
                minLabel: {type: :string}
              },
              additionalProperties: false
            },

            description: {type: :string},
            erkulIdentifier: {type: :string},
            focus: {type: :string},
            hasImages: {type: :boolean},
            hasModules: {type: :boolean},
            hasPaints: {type: :boolean},
            hasUpgrades: {type: :boolean},
            hasVideos: {type: :boolean},
            holo: {type: :string},
            lastPledgePrice: {type: :number},
            lastPledgePriceLabel: {type: :string},
            lastUpdatedAt: {type: :string, format: "date-time"},
            lastUpdatedAtLabel: {type: :string},

            links: {
              type: :object,
              properties: {
                salesPageUrl: {type: :string},
                storeUrl: {type: :string}
              },
              additionalProperties: false
            },

            loaners: {
              type: :array,
              items: {"$ref": "#/components/schemas/ModelLoaner"}
            },

            manufacturer: {"$ref": "#/components/schemas/Manufacturer"},

            media: {
              type: :object,
              properties: {
                angledView: {"$ref": "#/components/schemas/ViewImage"},
                angledViewColored: {"$ref": "#/components/schemas/ViewImage"},
                fleetchartImage: {type: :string},
                frontView: {"$ref": "#/components/schemas/ViewImage"},
                frontViewColored: {"$ref": "#/components/schemas/ViewImage"},
                sideView: {"$ref": "#/components/schemas/ViewImage"},
                sideViewColored: {"$ref": "#/components/schemas/ViewImage"},
                storeImage: {"$ref": "#/components/schemas/MediaImage"},
                topView: {"$ref": "#/components/schemas/ViewImage"},
                topViewColored: {"$ref": "#/components/schemas/ViewImage"}
              },
              additionalProperties: false
            },

            metrics: {
              type: :object,
              properties: {
                beam: {type: :number},
                beamLabel: {type: :string},
                cargo: {type: :number},
                cargoLabel: {type: :string},
                fleetchartLength: {type: :number},
                height: {type: :number},
                heightLabel: {type: :string},
                hydrogenFuelTankSize: {type: :number},
                isGroundVehicle: {type: :boolean},
                length: {type: :number},
                lengthLabel: {type: :string},
                mass: {type: :number},
                massLabel: {type: :string},
                quantumFuelTankSize: {type: :number},
                size: {type: :string},
                sizeLabel: {type: :string}
              },
              additionalProperties: false
            },

            onSale: {type: :boolean},
            pledgePrice: {type: :number},
            pledgePriceLabel: {type: :string},
            price: {type: :number},
            priceLabel: {type: :string},
            productionNote: {type: :string},
            productionStatus: {"$ref": "#/components/schemas/ModelProductionStatusEnum"},
            rsiId: {type: :integer},
            rsiName: {type: :string},
            rsiSlug: {type: :string},

            speeds: {
              type: :object,
              properties: {
                groundAcceleration: {type: :number},
                groundDecceleration: {type: :number},
                groundMaxSpeed: {type: :number},
                groundReverseSpeed: {type: :number},
                maxSpeed: {type: :number},
                maxSpeedAcceleration: {type: :number},
                maxSpeedDecceleration: {type: :number},
                pitch: {type: :number},
                roll: {type: :number},
                scmSpeed: {type: :number},
                scmSpeedAcceleration: {type: :number},
                scmSpeedDecceleration: {type: :number},
                yaw: {type: :number}
              },
              additionalProperties: false
            },

            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[
            id name slug availability crew hasImages hasModules hasPaints hasUpgrades hasVideos
            links loaners media metrics onSale speeds createdAt updatedAt
          ]
        })
      end
    end
  end
end
