# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class ModelsControllerTest < ActionDispatch::IntegrationTest
      let(:origin) { Model.find_by(slug: "600i") }

      it "should return list for index" do
        get "/api/v1/models", as: :json

        assert_response :ok
        json = JSON.parse response.body

        expected = [{
          "id" => origin.id,
          "name" => "600i",
          "scIdentifier" => nil,
          "erkulIdentifier" => nil,
          "rsiName" => nil,
          "slug" => "600i",
          "rsiSlug" => nil,
          "description" => nil,
          "length" => 20.0,
          "lengthLabel" => "20 m",
          "fleetchartLength" => 20.0,
          "beam" => 0.0,
          "beamLabel" => nil,
          "height" => 0.0,
          "heightLabel" => nil,
          "mass" => 0.0,
          "massLabel" => 0.0,
          "cargo" => 40.0,
          "cargoLabel" => "40 SCU",
          "hydrogenFuelTankSize" => nil,
          "quantumFuelTankSize" => nil,
          "minCrew" => 2,
          "minCrewLabel" => 2,
          "maxCrew" => 5,
          "maxCrewLabel" => 5,
          "scmSpeed" => nil,
          "afterburnerSpeed" => nil,
          "groundSpeed" => nil,
          "afterburnerGroundSpeed" => nil,
          "pitchMax" => nil,
          "yawMax" => nil,
          "rollMax" => nil,
          "xaxisAcceleration" => nil,
          "yaxisAcceleration" => nil,
          "zaxisAcceleration" => nil,
          "size" => nil,
          "sizeLabel" => nil,
          "media" => {
            "storeImage" => {
              "source" => origin.store_image.url,
              "small" => origin.store_image.small.url,
              "medium" => origin.store_image.medium.url,
              "large" => origin.store_image.large.url
            },
            "fleetchartImage" => nil,
            "angledView" => nil,
            "frontView" => nil,
            "sideView" => nil,
            "topView" => nil,
            "angledViewColored" => nil,
            "frontViewColored" => nil,
            "sideViewColored" => nil,
            "topViewColored" => nil
          },
          "storeImage" => origin.store_image.url,
          "storeImageLarge" => origin.store_image.large.url,
          "storeImageMedium" => origin.store_image.medium.url,
          "storeImageSmall" => origin.store_image.small.url,
          "fleetchartImage" => nil,
          "topView" => nil,
          "topViewSmall" => nil,
          "topViewMedium" => nil,
          "topViewLarge" => nil,
          "topViewXlarge" => nil,
          "topViewWidth" => nil,
          "topViewHeight" => nil,
          "sideView" => nil,
          "sideViewSmall" => nil,
          "sideViewMedium" => nil,
          "sideViewLarge" => nil,
          "sideViewXlarge" => nil,
          "sideViewWidth" => nil,
          "sideViewHeight" => nil,
          "angledView" => nil,
          "angledViewSmall" => nil,
          "angledViewMedium" => nil,
          "angledViewLarge" => nil,
          "angledViewXlarge" => nil,
          "angledViewWidth" => nil,
          "angledViewHeight" => nil,
          "brochure" => nil,
          "holo" => nil,
          "holoColored" => false,
          "storeUrl" => "https://robertsspaceindustries.com",
          "salesPageUrl" => nil,
          "price" => nil,
          "priceLabel" => nil,
          "pledgePrice" => nil,
          "pledgePriceLabel" => nil,
          "lastPledgePrice" => 400.0,
          "lastPledgePriceLabel" => "$400",
          "onSale" => false,
          "productionStatus" => nil,
          "productionNote" => nil,
          "classification" => "explorer",
          "classificationLabel" => "Explorer",
          "focus" => nil,
          "rsiId" => 14_101,
          "hasImages" => false,
          "hasVideos" => false,
          "hasModules" => false,
          "hasUpgrades" => false,
          "hasPaints" => false,
          "lastUpdatedAt" => origin.last_updated_at&.utc&.iso8601,
          "lastUpdatedAtLabel" => (I18n.l(Model.first.last_updated_at&.utc, format: :label) if origin.last_updated_at.present?),
          "soldAt" => [],
          "boughtAt" => [],
          "listedAt" => [{
            "id" => "e2befa3a-fe27-53f7-9405-268d23b2dfb7",
            "name" => "600i",
            "slug" => "600i",
            "media" => {
              "storeImage" => nil
            },
            "storeImage" =>
                    "http://localhost:3000/assets/fallback/store_image-fcc06a6ea7aa61c50d1758b22ccb76734440fe42ad80b87546f612b067d96394.jpg",
            "storeImageLarge" =>
                    "http://localhost:3000/assets/fallback/store_image-fcc06a6ea7aa61c50d1758b22ccb76734440fe42ad80b87546f612b067d96394.jpg",
            "storeImageMedium" =>
                    "http://localhost:3000/assets/fallback/store_image-fcc06a6ea7aa61c50d1758b22ccb76734440fe42ad80b87546f612b067d96394.jpg",
            "storeImageSmall" =>
                    "http://localhost:3000/assets/fallback/store_image-fcc06a6ea7aa61c50d1758b22ccb76734440fe42ad80b87546f612b067d96394.jpg",
            "category" => "model",
            "subCategory" => "explorer",
            "subCategoryLabel" => "Explorer",
            "description" => nil,
            "pricePerUnit" => false,
            "sellPrice" => nil,
            "averageSellPrice" => nil,
            "buyPrice" => nil,
            "averageBuyPrice" => nil,
            "rentalPrice1Day" => nil,
            "averageRentalPrice1Day" => nil,
            "rentalPrice3Days" => nil,
            "averageRentalPrice3Days" => nil,
            "rentalPrice7Days" => nil,
            "averageRentalPrice7Days" => nil,
            "rentalPrice30Days" => nil,
            "averageRentalPrice30Days" => nil,
            "locationLabel" => "sold at Dumpers Depot on Port Olisar",
            "confirmed" => true,
            "commodityItemType" => "Model",
            "commodityItemId" => "2e4b73e2-52bf-5b4c-8246-fb40ba397b38",
            "shop" => {
              "id" => "fd71143a-7403-50e3-a5c0-32f62ab537b6",
              "name" => "Dumpers Depot",
              "slug" => "dumpers-depot",
              "type" => "components",
              "typeLabel" => "Components Store",
              "stationLabel" => "at Port Olisar",
              "location" => nil,
              "locationLabel" => "at Port Olisar in orbit around Crusader",
              "rental" => false,
              "buying" => false,
              "selling" => false,
              "media" => {
                "storeImage" => nil
              },
              "storeImage" =>
                      "http://localhost:3000/assets/fallback/store_image-fcc06a6ea7aa61c50d1758b22ccb76734440fe42ad80b87546f612b067d96394.jpg",
              "storeImageLarge" =>
                      "http://localhost:3000/assets/fallback/store_image-fcc06a6ea7aa61c50d1758b22ccb76734440fe42ad80b87546f612b067d96394.jpg",
              "storeImageMedium" =>
                      "http://localhost:3000/assets/fallback/store_image-fcc06a6ea7aa61c50d1758b22ccb76734440fe42ad80b87546f612b067d96394.jpg",
              "storeImageSmall" =>
                      "http://localhost:3000/assets/fallback/store_image-fcc06a6ea7aa61c50d1758b22ccb76734440fe42ad80b87546f612b067d96394.jpg",
              "refineryTerminal" => nil,
              "station" => {
                "name" => "Port Olisar",
                "slug" => "port-olisar"
              }
            }
          }, {
            "id" => "46f72ce4-81f1-50d5-8428-5587ef23c320",
            "name" => "600i",
            "slug" => "600i",
            "media" => {
              "storeImage" => nil
            },
            "storeImage" =>
                    "http://localhost:3000/assets/fallback/store_image-fcc06a6ea7aa61c50d1758b22ccb76734440fe42ad80b87546f612b067d96394.jpg",
            "storeImageLarge" =>
                    "http://localhost:3000/assets/fallback/store_image-fcc06a6ea7aa61c50d1758b22ccb76734440fe42ad80b87546f612b067d96394.jpg",
            "storeImageMedium" =>
                    "http://localhost:3000/assets/fallback/store_image-fcc06a6ea7aa61c50d1758b22ccb76734440fe42ad80b87546f612b067d96394.jpg",
            "storeImageSmall" =>
                    "http://localhost:3000/assets/fallback/store_image-fcc06a6ea7aa61c50d1758b22ccb76734440fe42ad80b87546f612b067d96394.jpg",
            "category" => "model",
            "subCategory" => "explorer",
            "subCategoryLabel" => "Explorer",
            "description" => nil,
            "pricePerUnit" => false,
            "sellPrice" => nil,
            "averageSellPrice" => nil,
            "buyPrice" => nil,
            "averageBuyPrice" => nil,
            "rentalPrice1Day" => nil,
            "averageRentalPrice1Day" => nil,
            "rentalPrice3Days" => nil,
            "averageRentalPrice3Days" => nil,
            "rentalPrice7Days" => nil,
            "averageRentalPrice7Days" => nil,
            "rentalPrice30Days" => nil,
            "averageRentalPrice30Days" => nil,
            "locationLabel" => "sold at New Deal on Port Olisar",
            "confirmed" => true,
            "commodityItemType" => "Model",
            "commodityItemId" => "2e4b73e2-52bf-5b4c-8246-fb40ba397b38",
            "shop" => {
              "id" => "df2c9942-135d-5cbc-81d6-e1c14b6298bd",
              "name" => "New Deal",
              "slug" => "new-deal",
              "type" => "ships",
              "typeLabel" => "Ship Store",
              "stationLabel" => "at Port Olisar",
              "location" => nil,
              "locationLabel" => "at Port Olisar in orbit around Crusader",
              "rental" => false,
              "buying" => false,
              "selling" => false,
              "media" => {
                "storeImage" => nil
              },
              "storeImage" =>
                      "http://localhost:3000/assets/fallback/store_image-fcc06a6ea7aa61c50d1758b22ccb76734440fe42ad80b87546f612b067d96394.jpg",
              "storeImageLarge" =>
                      "http://localhost:3000/assets/fallback/store_image-fcc06a6ea7aa61c50d1758b22ccb76734440fe42ad80b87546f612b067d96394.jpg",
              "storeImageMedium" =>
                      "http://localhost:3000/assets/fallback/store_image-fcc06a6ea7aa61c50d1758b22ccb76734440fe42ad80b87546f612b067d96394.jpg",
              "storeImageSmall" =>
                      "http://localhost:3000/assets/fallback/store_image-fcc06a6ea7aa61c50d1758b22ccb76734440fe42ad80b87546f612b067d96394.jpg",
              "refineryTerminal" => nil,
              "station" => {
                "name" => "Port Olisar",
                "slug" => "port-olisar"
              }
            }
          }],
          "rentalAt" => [],
          "manufacturer" => {
            "name" => "Origin",
            "longName" => "Origin",
            "slug" => "origin",
            "code" => nil,
            "logo" => nil
          },
          "loaners" => [{
            "slug" => "ptv",
            "name" => "PTV"
          }],
          "createdAt" => origin.created_at.utc.iso8601,
          "updatedAt" => origin.updated_at.utc.iso8601
        }, {
          "id" => Model.last.id,
          "name" => "Andromeda",
          "scIdentifier" => nil,
          "erkulIdentifier" => nil,
          "rsiName" => nil,
          "slug" => "andromeda",
          "rsiSlug" => nil,
          "description" => nil,
          "length" => 61.2,
          "lengthLabel" => "61.2 m",
          "fleetchartLength" => 61.2,
          "beam" => 10.2,
          "beamLabel" => "10.2 m",
          "height" => 10.2,
          "heightLabel" => "10.2 m",
          "mass" => 1000.02,
          "massLabel" => 1000.02,
          "cargo" => 90.0,
          "cargoLabel" => "90 SCU",
          "hydrogenFuelTankSize" => nil,
          "quantumFuelTankSize" => nil,
          "minCrew" => 3,
          "minCrewLabel" => 3,
          "maxCrew" => 5,
          "maxCrewLabel" => 5,
          "scmSpeed" => nil,
          "afterburnerSpeed" => nil,
          "groundSpeed" => nil,
          "afterburnerGroundSpeed" => nil,
          "pitchMax" => nil,
          "yawMax" => nil,
          "rollMax" => nil,
          "xaxisAcceleration" => nil,
          "yaxisAcceleration" => nil,
          "zaxisAcceleration" => nil,
          "size" => nil,
          "sizeLabel" => nil,

          "media" => {
            "storeImage" => {
              "source" => Model.last.store_image.url,
              "small" => Model.last.store_image.small.url,
              "medium" => Model.last.store_image.medium.url,
              "large" => Model.last.store_image.large.url
            },
            "fleetchartImage" => nil,
            "angledView" => nil,
            "frontView" => nil,
            "sideView" => nil,
            "topView" => nil,
            "angledViewColored" => nil,
            "frontViewColored" => nil,
            "sideViewColored" => nil,
            "topViewColored" => nil
          },
          "storeImage" => Model.last.store_image.url,
          "storeImageLarge" => Model.last.store_image.large.url,
          "storeImageMedium" => Model.last.store_image.medium.url,
          "storeImageSmall" => Model.last.store_image.small.url,
          "fleetchartImage" => nil,
          "topView" => nil,
          "topViewSmall" => nil,
          "topViewMedium" => nil,
          "topViewLarge" => nil,
          "topViewXlarge" => nil,
          "topViewWidth" => nil,
          "topViewHeight" => nil,
          "sideView" => nil,
          "sideViewSmall" => nil,
          "sideViewMedium" => nil,
          "sideViewLarge" => nil,
          "sideViewXlarge" => nil,
          "sideViewWidth" => nil,
          "sideViewHeight" => nil,
          "angledView" => nil,
          "angledViewSmall" => nil,
          "angledViewMedium" => nil,
          "angledViewLarge" => nil,
          "angledViewXlarge" => nil,
          "angledViewWidth" => nil,
          "angledViewHeight" => nil,
          "brochure" => nil,
          "holo" => nil,
          "holoColored" => false,
          "storeUrl" => "https://robertsspaceindustries.com",
          "salesPageUrl" => nil,
          "price" => nil,
          "priceLabel" => nil,
          "pledgePrice" => nil,
          "pledgePriceLabel" => nil,
          "lastPledgePrice" => 225.0,
          "lastPledgePriceLabel" => "$225",
          "onSale" => false,
          "productionStatus" => nil,
          "productionNote" => nil,
          "classification" => "multi_role",
          "classificationLabel" => "Multi role",
          "focus" => nil,
          "rsiId" => 14_100,
          "hasImages" => false,
          "hasVideos" => false,
          "hasModules" => false,
          "hasUpgrades" => false,
          "hasPaints" => false,
          "lastUpdatedAt" => Model.last.last_updated_at&.utc&.iso8601,
          "lastUpdatedAtLabel" => (I18n.l(Model.last.last_updated_at&.utc, format: :label) if Model.last.last_updated_at.present?),
          "soldAt" => [],
          "boughtAt" => [],
          "listedAt" => [{
            "id" => "c38015d3-a8f7-5419-9aed-03e80ec3169a",
            "name" => "Andromeda",
            "slug" => "andromeda",
            "media" => {
              "storeImage" => nil
            },
            "storeImage" =>
                    "http://localhost:3000/assets/fallback/store_image-fcc06a6ea7aa61c50d1758b22ccb76734440fe42ad80b87546f612b067d96394.jpg",
            "storeImageLarge" =>
                    "http://localhost:3000/assets/fallback/store_image-fcc06a6ea7aa61c50d1758b22ccb76734440fe42ad80b87546f612b067d96394.jpg",
            "storeImageMedium" =>
                    "http://localhost:3000/assets/fallback/store_image-fcc06a6ea7aa61c50d1758b22ccb76734440fe42ad80b87546f612b067d96394.jpg",
            "storeImageSmall" =>
                    "http://localhost:3000/assets/fallback/store_image-fcc06a6ea7aa61c50d1758b22ccb76734440fe42ad80b87546f612b067d96394.jpg",
            "category" => "model",
            "subCategory" => "multi_role",
            "subCategoryLabel" => "Multi role",
            "description" => nil,
            "pricePerUnit" => false,
            "sellPrice" => nil,
            "averageSellPrice" => nil,
            "buyPrice" => nil,
            "averageBuyPrice" => nil,
            "rentalPrice1Day" => nil,
            "averageRentalPrice1Day" => nil,
            "rentalPrice3Days" => nil,
            "averageRentalPrice3Days" => nil,
            "rentalPrice7Days" => nil,
            "averageRentalPrice7Days" => nil,
            "rentalPrice30Days" => nil,
            "averageRentalPrice30Days" => nil,
            "locationLabel" => "sold at New Deal on Port Olisar",
            "confirmed" => true,
            "commodityItemType" => "Model",
            "commodityItemId" => "f5412c18-0c29-5b52-b503-ad58947dbe13",
            "shop" => {
              "id" => "df2c9942-135d-5cbc-81d6-e1c14b6298bd",
              "name" => "New Deal",
              "slug" => "new-deal",
              "type" => "ships",
              "typeLabel" => "Ship Store",
              "stationLabel" => "at Port Olisar",
              "location" => nil,
              "locationLabel" => "at Port Olisar in orbit around Crusader",
              "rental" => false,
              "buying" => false,
              "selling" => false,
              "media" => {
                "storeImage" => nil
              },
              "storeImage" =>
              "http://localhost:3000/assets/fallback/store_image-fcc06a6ea7aa61c50d1758b22ccb76734440fe42ad80b87546f612b067d96394.jpg",
              "storeImageLarge" =>
              "http://localhost:3000/assets/fallback/store_image-fcc06a6ea7aa61c50d1758b22ccb76734440fe42ad80b87546f612b067d96394.jpg",
              "storeImageMedium" =>
              "http://localhost:3000/assets/fallback/store_image-fcc06a6ea7aa61c50d1758b22ccb76734440fe42ad80b87546f612b067d96394.jpg",
              "storeImageSmall" =>
              "http://localhost:3000/assets/fallback/store_image-fcc06a6ea7aa61c50d1758b22ccb76734440fe42ad80b87546f612b067d96394.jpg",
              "refineryTerminal" => nil,
              "station" => {
                "name" => "Port Olisar",
                "slug" => "port-olisar"
              }
            }
          }],
          "rentalAt" => [],
          "manufacturer" => {
            "name" => "RSI",
            "longName" => "RSI",
            "slug" => "rsi",
            "code" => nil,
            "logo" => nil
          },
          "loaners" => [],
          "createdAt" => Model.last.created_at.utc.iso8601,
          "updatedAt" => Model.last.updated_at.utc.iso8601
        }]

        assert_equal expected, json
      end

      it "should be able to filter the list" do
        get "/api/v1/models", params: {q: '{ "nameCont": "Andromeda" }'}, as: :json

        assert_response :ok
        json = JSON.parse response.body

        assert_equal 1, json.count
        assert_equal "Andromeda", json.first["name"]
      end

      it "should be able to reduce per page size" do
        get "/api/v1/models", params: {perPage: "15"}, as: :json

        assert_response :ok
        json = JSON.parse response.body

        # result count is 2 because there are only 2 models in the database
        assert_equal 2, json.count
      end
    end
  end
end
