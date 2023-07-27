# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Model
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            scIdentifier: {type: :string, nullable: true},
            name: {type: :string},
            slug: {type: :string},

            availability: {
              type: :object,
              properties: {
                boughtAt: {
                  type: :array,
                  items: {"$ref": "#/components/schemas/ShopCommodity"}
                },
                listedAt: {
                  type: :array,
                  items: {"$ref": "#/components/schemas/ShopCommodity"}
                },
                rentalAt: {
                  type: :array,
                  items: {"$ref": "#/components/schemas/ShopCommodity"}
                },
                soldAt: {
                  type: :array,
                  items: {"$ref": "#/components/schemas/ShopCommodity"}
                }
              },
              required: %w[boughtAt listedAt rentalAt soldAt]
            },

            brochure: {type: :string, nullable: true},
            classification: {type: :string, nullable: true},
            classificationLabel: {type: :string, nullable: true},

            crew: {
              type: :object,
              properties: {
                max: {type: :number, nullable: true},
                maxLabel: {type: :string, nullable: true},
                min: {type: :number, nullable: true},
                minLabel: {type: :string, nullable: true}
              }
            },

            description: {type: :string, nullable: true},
            erkulIdentifier: {type: :string, nullable: true},
            focus: {type: :string, nullable: true},
            hasImages: {type: :boolean},
            hasModules: {type: :boolean},
            hasPaints: {type: :boolean},
            hasUpgrades: {type: :boolean},
            hasVideos: {type: :boolean},
            holo: {type: :string, nullable: true},
            holoColored: {type: :boolean, nullable: true, deprecated: true},
            lastPledgePrice: {type: :number, nullable: true},
            lastPledgePriceLabel: {type: :string, nullable: true},
            lastUpdatedAt: {type: :string, format: "date-time", nullable: true},
            lastUpdatedAtLabel: {type: :string, nullable: true},

            links: {
              type: :object,
              properties: {
                salesPageUrl: {type: :string, nullable: true},
                storeUrl: {type: :string, nullable: true}
              }
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
                fleetchartImage: {type: :string, nullable: true},
                frontView: {"$ref": "#/components/schemas/ViewImage"},
                frontViewColored: {"$ref": "#/components/schemas/ViewImage"},
                sideView: {"$ref": "#/components/schemas/ViewImage"},
                sideViewColored: {"$ref": "#/components/schemas/ViewImage"},
                storeImage: {"$ref": "#/components/schemas/MediaImage"},
                topView: {"$ref": "#/components/schemas/ViewImage"},
                topViewColored: {"$ref": "#/components/schemas/ViewImage"}
              }
            },

            metrics: {
              type: :object,
              properties: {
                beam: {type: :number, nullable: true},
                beamLabel: {type: :string, nullable: true},
                cargo: {type: :number, nullable: true},
                cargoLabel: {type: :string, nullable: true},
                fleetchartLength: {type: :number, nullable: true},
                height: {type: :number, nullable: true},
                heightLabel: {type: :string, nullable: true},
                hydrogenFuelTankSize: {type: :number, nullable: true},
                isGroundVehicle: {type: :boolean},
                length: {type: :number, nullable: true},
                lengthLabel: {type: :string, nullable: true},
                mass: {type: :number, nullable: true},
                massLabel: {type: :string, nullable: true},
                quantumFuelTankSize: {type: :number, nullable: true},
                size: {type: :string, nullable: true},
                sizeLabel: {type: :string, nullable: true}
              }
            },

            onSale: {type: :boolean},
            pledgePrice: {type: :number, nullable: true},
            pledgePriceLabel: {type: :string, nullable: true},
            price: {type: :number, nullable: true},
            priceLabel: {type: :string, nullable: true},
            productionNote: {type: :string, nullable: true},
            productionStatus: {type: :string, nullable: true},
            rsiId: {type: :integer, nullable: true},
            rsiName: {type: :string, nullable: true},
            rsiSlug: {type: :string, nullable: true},

            speeds: {
              type: :object,
              properties: {
                groundAcceleration: {type: :number, nullable: true},
                groundDecceleration: {type: :number, nullable: true},
                groundMaxSpeed: {type: :number, nullable: true},
                groundReverseSpeed: {type: :number, nullable: true},
                maxSpeed: {type: :number, nullable: true},
                maxSpeedAcceleration: {type: :number, nullable: true},
                maxSpeedDecceleration: {type: :number, nullable: true},
                pitch: {type: :number, nullable: true},
                roll: {type: :number, nullable: true},
                scmSpeed: {type: :number, nullable: true},
                scmSpeedAcceleration: {type: :number, nullable: true},
                scmSpeedDecceleration: {type: :number, nullable: true},
                yaw: {type: :number, nullable: true}
              }
            }
          },
          additionalProperties: false,
          required: %w[
            id name slug availability crew hasImages hasModules hasPaints hasUpgrades hasVideos links loaners
            metrics onSale speeds
          ]
        })
      end
    end
  end
end
