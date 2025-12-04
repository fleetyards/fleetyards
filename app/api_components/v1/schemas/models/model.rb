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
                listedAt: {
                  type: :array,
                  items: {"$ref": "#/components/schemas/ShopCommodity"}
                },
                boughtAt: {
                  type: :array,
                  items: {"$ref": "#/components/schemas/ShopCommodity"}
                },
                soldAt: {
                  type: :array,
                  items: {"$ref": "#/components/schemas/ShopCommodity"}
                },
                rentalAt: {
                  type: :array,
                  items: {"$ref": "#/components/schemas/ShopCommodity"}
                }
              },
              additionalProperties: false,
              required: %w[listedAt boughtAt soldAt rentalAt]
            },

            brochure: {type: :string},
            classification: {type: :string},
            classificationLabel: {type: :string},

            map: {type: :boolean, default: false},

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
            holoColored: {type: :boolean, deprecated: true},
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
            productionStatus: {type: :string},
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
            updatedAt: {type: :string, format: "date-time"},

            # DEPRECATED

            afterburnerGroundSpeed: {type: :number, deprecated: true},
            afterburnerSpeed: {type: :number, deprecated: true},
            angledView: {type: :string, deprecated: true},
            angledViewHeight: {type: :number, deprecated: true},
            angledViewLarge: {type: :string, deprecated: true},
            angledViewMedium: {type: :string, deprecated: true},
            angledViewSmall: {type: :string, deprecated: true},
            angledViewWidth: {type: :number, deprecated: true},
            angledViewXlarge: {type: :string, deprecated: true},
            beam: {type: :number, deprecated: true},
            beamLabel: {type: :string, deprecated: true},
            cargo: {type: :number, deprecated: true},
            cargoLabel: {type: :string, deprecated: true},
            fleetchartImage: {type: :string, deprecated: true},
            fleetchartLength: {type: :number, deprecated: true},
            groundSpeed: {type: :number, deprecated: true},
            height: {type: :number, deprecated: true},
            heightLabel: {type: :string, deprecated: true},
            hydrogenFuelTankSize: {type: :number, deprecated: true},
            length: {type: :number, deprecated: true},
            lengthLabel: {type: :string, deprecated: true},
            mass: {type: :number, deprecated: true},
            massLabel: {type: :number, deprecated: true},
            maxCrew: {type: :integer, deprecated: true},
            maxCrewLabel: {type: :string, deprecated: true},
            minCrew: {type: :integer, deprecated: true},
            minCrewLabel: {type: :string, deprecated: true},
            pitchMax: {type: :number, deprecated: true},
            quantumFuelTankSize: {type: :number, deprecated: true},
            rollMax: {type: :number, deprecated: true},
            salesPageUrl: {type: :string, deprecated: true},
            scmSpeed: {type: :number, deprecated: true},
            sideView: {type: :string, deprecated: true},
            sideViewHeight: {type: :number, deprecated: true},
            sideViewLarge: {type: :string, deprecated: true},
            sideViewMedium: {type: :string, deprecated: true},
            sideViewSmall: {type: :string, deprecated: true},
            sideViewWidth: {type: :number, deprecated: true},
            sideViewXlarge: {type: :string, deprecated: true},
            size: {type: :string, deprecated: true},
            sizeLabel: {type: :string, deprecated: true},
            storeImage: {type: :string, deprecated: true},
            storeImageLarge: {type: :string, deprecated: true},
            storeImageMedium: {type: :string, deprecated: true},
            storeImageSmall: {type: :string, deprecated: true},
            storeUrl: {type: :string, deprecated: true},
            topView: {type: :string, deprecated: true},
            topViewHeight: {type: :number, deprecated: true},
            topViewLarge: {type: :string, deprecated: true},
            topViewMedium: {type: :string, deprecated: true},
            topViewSmall: {type: :string, deprecated: true},
            topViewWidth: {type: :number, deprecated: true},
            topViewXlarge: {type: :string, deprecated: true},
            xaxisAcceleration: {type: :number, deprecated: true},
            yawMax: {type: :number, deprecated: true},
            yaxisAcceleration: {type: :number, deprecated: true},
            zaxisAcceleration: {type: :number, deprecated: true}
          },
          additionalProperties: false,
          required: %w[
            id name slug availability crew hasImages hasModules hasPaints hasUpgrades hasVideos
            links loaners media metrics onSale speeds map createdAt updatedAt
          ]
        })
      end
    end
  end
end
