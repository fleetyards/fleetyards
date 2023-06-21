# frozen_string_literal: true

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

          manufacturer: {"$ref": "#/components/schemas/Manufacturer", nullable: true},

          media: {
            type: :object,
            properties: {
              angledView: {"$ref": "#/components/schemas/ViewImage", nullable: true},
              angledViewColored: {"$ref": "#/components/schemas/ViewImage", nullable: true},
              fleetchartImage: {type: :string, nullable: true},
              frontView: {"$ref": "#/components/schemas/ViewImage", nullable: true},
              frontViewColored: {"$ref": "#/components/schemas/ViewImage", nullable: true},
              sideView: {"$ref": "#/components/schemas/ViewImage", nullable: true},
              sideViewColored: {"$ref": "#/components/schemas/ViewImage", nullable: true},
              storeImage: {"$ref": "#/components/schemas/MediaImage", nullable: true},
              topView: {"$ref": "#/components/schemas/ViewImage", nullable: true},
              topViewColored: {"$ref": "#/components/schemas/ViewImage", nullable: true}
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
          },

          # deprecated

          afterburnerGroundSpeed: {type: :number, nullable: true, deprecated: true},
          afterburnerSpeed: {type: :number, nullable: true, deprecated: true},
          angledView: {type: :string, nullable: true, deprecated: true},
          angledViewHeight: {type: :number, nullable: true, deprecated: true},
          angledViewLarge: {type: :string, nullable: true, deprecated: true},
          angledViewMedium: {type: :string, nullable: true, deprecated: true},
          angledViewSmall: {type: :string, nullable: true, deprecated: true},
          angledViewWidth: {type: :number, nullable: true, deprecated: true},
          angledViewXlarge: {type: :string, nullable: true, deprecated: true},
          beam: {type: :number, nullable: true, deprecated: true},
          beamLabel: {type: :string, nullable: true, deprecated: true},
          cargo: {type: :number, nullable: true, deprecated: true},
          cargoLabel: {type: :string, nullable: true, deprecated: true},
          fleetchartImage: {type: :string, nullable: true, deprecated: true},
          fleetchartLength: {type: :number, nullable: true, deprecated: true},
          groundSpeed: {type: :number, nullable: true, deprecated: true},
          height: {type: :number, nullable: true, deprecated: true},
          heightLabel: {type: :string, nullable: true, deprecated: true},
          hydrogenFuelTankSize: {type: :number, nullable: true, deprecated: true},
          length: {type: :number, nullable: true, deprecated: true},
          lengthLabel: {type: :string, nullable: true, deprecated: true},
          mass: {type: :number, nullable: true, deprecated: true},
          massLabel: {type: :number, nullable: true, deprecated: true},
          maxCrew: {type: :number, nullable: true, deprecated: true},
          maxCrewLabel: {type: :number, nullable: true, deprecated: true},
          minCrew: {type: :number, nullable: true, deprecated: true},
          minCrewLabel: {type: :number, nullable: true, deprecated: true},
          pitchMax: {type: :number, nullable: true, deprecated: true},
          quantumFuelTankSize: {type: :number, nullable: true, deprecated: true},
          rollMax: {type: :number, nullable: true, deprecated: true},
          salesPageUrl: {type: :string, nullable: true, deprecated: true},
          scmSpeed: {type: :number, nullable: true, deprecated: true},
          sideView: {type: :string, nullable: true, deprecated: true},
          sideViewHeight: {type: :number, nullable: true, deprecated: true},
          sideViewLarge: {type: :string, nullable: true, deprecated: true},
          sideViewMedium: {type: :string, nullable: true, deprecated: true},
          sideViewSmall: {type: :string, nullable: true, deprecated: true},
          sideViewWidth: {type: :number, nullable: true, deprecated: true},
          sideViewXlarge: {type: :string, nullable: true, deprecated: true},
          size: {type: :number, nullable: true, deprecated: true},
          sizeLabel: {type: :string, nullable: true, deprecated: true},
          storeImage: {type: :string, nullable: true, deprecated: true},
          storeImageLarge: {type: :string, nullable: true, deprecated: true},
          storeImageMedium: {type: :string, nullable: true, deprecated: true},
          storeImageSmall: {type: :string, nullable: true, deprecated: true},
          storeUrl: {type: :string, nullable: true, deprecated: true},
          topView: {type: :string, nullable: true, deprecated: true},
          topViewHeight: {type: :number, nullable: true, deprecated: true},
          topViewLarge: {type: :string, nullable: true, deprecated: true},
          topViewMedium: {type: :string, nullable: true, deprecated: true},
          topViewSmall: {type: :string, nullable: true, deprecated: true},
          topViewWidth: {type: :number, nullable: true, deprecated: true},
          topViewXlarge: {type: :string, nullable: true, deprecated: true},
          xaxisAcceleration: {type: :number, nullable: true, deprecated: true},
          yawMax: {type: :number, nullable: true, deprecated: true},
          yaxisAcceleration: {type: :number, nullable: true, deprecated: true},
          zaxisAcceleration: {type: :number, nullable: true, deprecated: true}
        },
        required: %w[
          id name slug availability crew hasImages hasModules hasPaints hasUpgrades hasVideos links loaners
          media metrics onSale speeds
        ]
      })
    end
  end
end
