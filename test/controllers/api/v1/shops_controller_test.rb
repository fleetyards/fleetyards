# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class ShopsControllerTest < ActionDispatch::IntegrationTest
      let(:crusader) { celestial_objects :crusader }
      let(:yela) { celestial_objects :yela }
      let(:daymar) { celestial_objects :daymar }
      let(:new_deal) { shops :new_deal }
      let(:dumpers) { shops :dumpers }
      let(:admin_olisar) { shops :admin_olisar }
      let(:admin_daymar) { shops :admin_daymar }
      let(:admin_yela) { shops :admin_yela }
      let(:show_result) do
        {
          "id" => new_deal.id,
          "name" => "New Deal",
          "slug" => "new-deal",
          "type" => "ships",
          "typeLabel" => "Ship Store",
          "stationLabel" => new_deal.station_label,
          "location" => new_deal.location,
          "locationLabel" => new_deal.location_label,
          "rental" => false,
          "buying" => false,
          "selling" => false,
          "storeImage" => new_deal.store_image.url,
          "storeImageLarge" => new_deal.store_image.large.url,
          "storeImageMedium" => new_deal.store_image.medium.url,
          "storeImageSmall" => new_deal.store_image.small.url,
          "refineryTerminal" => nil,
          "station" => {
            "name" => "Port Olisar",
            "slug" => "port-olisar"
          },
          "celestialObject" => {
            "name" => "Crusader",
            "slug" => "crusader",
            "type" => nil,
            "designation" => "2",
            "storeImage" => crusader.store_image.url,
            "storeImageLarge" => crusader.store_image.large.url,
            "storeImageMedium" => crusader.store_image.medium.url,
            "storeImageSmall" => crusader.store_image.small.url,
            "description" => nil,
            "habitable" => nil,
            "fairchanceact" => nil,
            "subType" => nil,
            "size" => nil,
            "danger" => nil,
            "economy" => nil,
            "population" => nil,
            "locationLabel" => crusader.location_label,
            "starsystem" => {
              "name" => "Stanton",
              "slug" => "stanton",
              "storeImage" => crusader.starsystem.store_image.url,
              "storeImageLarge" => crusader.starsystem.store_image.large.url,
              "storeImageMedium" => crusader.starsystem.store_image.medium.url,
              "storeImageSmall" => crusader.starsystem.store_image.small.url,
              "mapX" => nil,
              "mapY" => nil,
              "description" => nil,
              "type" => nil,
              "size" => nil,
              "population" => nil,
              "economy" => nil,
              "danger" => nil,
              "status" => nil,
              "locationLabel" => crusader.starsystem.location_label
            }
          },
          "createdAt" => new_deal.created_at.utc.iso8601,
          "updatedAt" => new_deal.updated_at.utc.iso8601
        }
      end
      let(:index_result) do
        [{
          "id" => admin_daymar.id,
          "name" => "Admin Office",
          "slug" => "admin-office",
          "type" => "admin",
          "typeLabel" => "Admin Office",
          "stationLabel" => admin_daymar.station_label,
          "location" => admin_daymar.location,
          "locationLabel" => admin_daymar.location_label,
          "rental" => false,
          "buying" => false,
          "selling" => false,
          "storeImage" => admin_daymar.store_image.url,
          "storeImageLarge" => admin_daymar.store_image.large.url,
          "storeImageMedium" => admin_daymar.store_image.medium.url,
          "storeImageSmall" => admin_daymar.store_image.small.url,
          "refineryTerminal" => nil,
          "station" => {
            "name" => "ArcCorp 001",
            "slug" => "arccorp_daymar"
          },
          "celestialObject" => {
            "name" => "Daymar",
            "slug" => "daymar",
            "type" => nil,
            "designation" => "4",
            "storeImage" => daymar.store_image.url,
            "storeImageLarge" => daymar.store_image.large.url,
            "storeImageMedium" => daymar.store_image.medium.url,
            "storeImageSmall" => daymar.store_image.small.url,
            "description" => nil,
            "habitable" => nil,
            "fairchanceact" => nil,
            "subType" => nil,
            "size" => nil,
            "danger" => nil,
            "economy" => nil,
            "population" => nil,
            "locationLabel" => daymar.location_label,
            "parent" => {
              "name" => "Crusader",
              "slug" => "crusader",
              "type" => nil,
              "designation" => "2",
              "storeImage" => crusader.store_image.url,
              "storeImageLarge" => crusader.store_image.large.url,
              "storeImageMedium" => crusader.store_image.medium.url,
              "storeImageSmall" => crusader.store_image.small.url,
              "description" => nil,
              "habitable" => nil,
              "fairchanceact" => nil,
              "subType" => nil,
              "size" => nil,
              "danger" => nil,
              "economy" => nil,
              "population" => nil,
              "locationLabel" => crusader.location_label,
              "starsystem" => {
                "name" => "Stanton",
                "slug" => "stanton",
                "storeImage" => crusader.starsystem.store_image.url,
                "storeImageLarge" => crusader.starsystem.store_image.large.url,
                "storeImageMedium" => crusader.starsystem.store_image.medium.url,
                "storeImageSmall" => crusader.starsystem.store_image.small.url,
                "mapX" => nil,
                "mapY" => nil,
                "description" => nil,
                "type" => nil,
                "size" => nil,
                "population" => nil,
                "economy" => nil,
                "danger" => nil,
                "status" => nil,
                "locationLabel" => crusader.starsystem.location_label
              }
            },
            "starsystem" => {
              "name" => "Stanton",
              "slug" => "stanton",
              "storeImage" => crusader.starsystem.store_image.url,
              "storeImageLarge" => crusader.starsystem.store_image.large.url,
              "storeImageMedium" => crusader.starsystem.store_image.medium.url,
              "storeImageSmall" => crusader.starsystem.store_image.small.url,
              "mapX" => nil,
              "mapY" => nil,
              "description" => nil,
              "type" => nil,
              "size" => nil,
              "population" => nil,
              "economy" => nil,
              "danger" => nil,
              "status" => nil,
              "locationLabel" => crusader.starsystem.location_label
            }
          },
          "createdAt" => admin_daymar.created_at.utc.iso8601,
          "updatedAt" => admin_daymar.updated_at.utc.iso8601
        }, {
          "id" => admin_yela.id,
          "name" => "Admin Office",
          "slug" => "admin-office",
          "type" => "admin",
          "typeLabel" => "Admin Office",
          "stationLabel" => admin_yela.station_label,
          "location" => admin_yela.location,
          "locationLabel" => admin_yela.location_label,
          "rental" => false,
          "buying" => false,
          "selling" => false,
          "storeImage" => admin_yela.store_image.url,
          "storeImageLarge" => admin_yela.store_image.large.url,
          "storeImageMedium" => admin_yela.store_image.medium.url,
          "storeImageSmall" => admin_yela.store_image.small.url,
          "refineryTerminal" => nil,
          "station" => {
            "name" => "ArcCorp 002",
            "slug" => "arccorp_yela"
          },
          "celestialObject" => {
            "name" => "Yela",
            "slug" => "yela",
            "type" => nil,
            "designation" => "3",
            "storeImage" => yela.store_image.url,
            "storeImageLarge" => yela.store_image.large.url,
            "storeImageMedium" => yela.store_image.medium.url,
            "storeImageSmall" => yela.store_image.small.url,
            "description" => nil,
            "habitable" => nil,
            "fairchanceact" => nil,
            "subType" => nil,
            "size" => nil,
            "danger" => nil,
            "economy" => nil,
            "population" => nil,
            "locationLabel" => yela.location_label,
            "parent" => {
              "name" => "Crusader",
              "slug" => "crusader",
              "type" => nil,
              "designation" => "2",
              "storeImage" => crusader.store_image.url,
              "storeImageLarge" => crusader.store_image.large.url,
              "storeImageMedium" => crusader.store_image.medium.url,
              "storeImageSmall" => crusader.store_image.small.url,
              "description" => nil,
              "habitable" => nil,
              "fairchanceact" => nil,
              "subType" => nil,
              "size" => nil,
              "danger" => nil,
              "economy" => nil,
              "population" => nil,
              "locationLabel" => crusader.location_label,
              "starsystem" => {
                "name" => "Stanton",
                "slug" => "stanton",
                "storeImage" => crusader.starsystem.store_image.url,
                "storeImageLarge" => crusader.starsystem.store_image.large.url,
                "storeImageMedium" => crusader.starsystem.store_image.medium.url,
                "storeImageSmall" => crusader.starsystem.store_image.small.url,
                "mapX" => nil,
                "mapY" => nil,
                "description" => nil,
                "type" => nil,
                "size" => nil,
                "population" => nil,
                "economy" => nil,
                "danger" => nil,
                "status" => nil,
                "locationLabel" => crusader.starsystem.location_label
              }
            },
            "starsystem" => {
              "name" => "Stanton",
              "slug" => "stanton",
              "storeImage" => crusader.starsystem.store_image.url,
              "storeImageLarge" => crusader.starsystem.store_image.large.url,
              "storeImageMedium" => crusader.starsystem.store_image.medium.url,
              "storeImageSmall" => crusader.starsystem.store_image.small.url,
              "description" => nil,
              "mapX" => nil,
              "mapY" => nil,
              "type" => nil,
              "size" => nil,
              "population" => nil,
              "economy" => nil,
              "danger" => nil,
              "status" => nil,
              "locationLabel" => crusader.starsystem.location_label
            }
          },
          "createdAt" => admin_yela.created_at.utc.iso8601,
          "updatedAt" => admin_yela.updated_at.utc.iso8601
        }, {
          "id" => admin_olisar.id,
          "name" => "Admin Office",
          "slug" => "admin-office",
          "type" => "admin",
          "typeLabel" => "Admin Office",
          "stationLabel" => admin_olisar.station_label,
          "location" => admin_olisar.location,
          "locationLabel" => admin_olisar.location_label,
          "rental" => false,
          "buying" => false,
          "selling" => false,
          "storeImage" => admin_olisar.store_image.url,
          "storeImageLarge" => admin_olisar.store_image.large.url,
          "storeImageMedium" => admin_olisar.store_image.medium.url,
          "storeImageSmall" => admin_olisar.store_image.small.url,
          "refineryTerminal" => nil,
          "station" => {
            "name" => "Port Olisar",
            "slug" => "port-olisar"
          },
          "celestialObject" => {
            "name" => "Crusader",
            "slug" => "crusader",
            "type" => nil,
            "designation" => "2",
            "storeImage" => crusader.store_image.url,
            "storeImageLarge" => crusader.store_image.large.url,
            "storeImageMedium" => crusader.store_image.medium.url,
            "storeImageSmall" => crusader.store_image.small.url,
            "description" => nil,
            "habitable" => nil,
            "fairchanceact" => nil,
            "subType" => nil,
            "size" => nil,
            "danger" => nil,
            "economy" => nil,
            "population" => nil,
            "locationLabel" => crusader.location_label,
            "starsystem" => {
              "name" => "Stanton",
              "slug" => "stanton",
              "storeImage" => crusader.starsystem.store_image.url,
              "storeImageLarge" => crusader.starsystem.store_image.large.url,
              "storeImageMedium" => crusader.starsystem.store_image.medium.url,
              "storeImageSmall" => crusader.starsystem.store_image.small.url,
              "mapX" => nil,
              "mapY" => nil,
              "description" => nil,
              "type" => nil,
              "size" => nil,
              "population" => nil,
              "economy" => nil,
              "danger" => nil,
              "status" => nil,
              "locationLabel" => crusader.starsystem.location_label
            }
          },
          "createdAt" => admin_olisar.created_at.utc.iso8601,
          "updatedAt" => admin_olisar.updated_at.utc.iso8601
        }, {
          "id" => dumpers.id,
          "name" => "Dumpers Depot",
          "slug" => "dumpers-depot",
          "type" => "components",
          "typeLabel" => "Components Store",
          "stationLabel" => dumpers.station_label,
          "location" => dumpers.location,
          "locationLabel" => dumpers.location_label,
          "rental" => false,
          "buying" => false,
          "selling" => false,
          "storeImage" => dumpers.store_image.url,
          "storeImageLarge" => dumpers.store_image.large.url,
          "storeImageMedium" => dumpers.store_image.medium.url,
          "storeImageSmall" => dumpers.store_image.small.url,
          "refineryTerminal" => nil,
          "station" => {
            "name" => "Port Olisar",
            "slug" => "port-olisar"
          },
          "celestialObject" => {
            "name" => "Crusader",
            "slug" => "crusader",
            "type" => nil,
            "designation" => "2",
            "storeImage" => crusader.store_image.url,
            "storeImageLarge" => crusader.store_image.large.url,
            "storeImageMedium" => crusader.store_image.medium.url,
            "storeImageSmall" => crusader.store_image.small.url,
            "description" => nil,
            "habitable" => nil,
            "fairchanceact" => nil,
            "subType" => nil,
            "size" => nil,
            "danger" => nil,
            "economy" => nil,
            "population" => nil,
            "locationLabel" => crusader.location_label,
            "starsystem" => {
              "name" => "Stanton",
              "slug" => "stanton",
              "storeImage" => crusader.starsystem.store_image.url,
              "storeImageLarge" => crusader.starsystem.store_image.large.url,
              "storeImageMedium" => crusader.starsystem.store_image.medium.url,
              "storeImageSmall" => crusader.starsystem.store_image.small.url,
              "mapX" => nil,
              "mapY" => nil,
              "description" => nil,
              "type" => nil,
              "size" => nil,
              "population" => nil,
              "economy" => nil,
              "danger" => nil,
              "status" => nil,
              "locationLabel" => crusader.starsystem.location_label
            }
          },
          "createdAt" => dumpers.created_at.utc.iso8601,
          "updatedAt" => dumpers.updated_at.utc.iso8601
        }, {
          "id" => new_deal.id,
          "name" => "New Deal",
          "slug" => "new-deal",
          "type" => "ships",
          "typeLabel" => "Ship Store",
          "stationLabel" => new_deal.station_label,
          "location" => new_deal.location,
          "locationLabel" => new_deal.location_label,
          "rental" => false,
          "buying" => false,
          "selling" => false,
          "storeImage" => new_deal.store_image.url,
          "storeImageLarge" => new_deal.store_image.large.url,
          "storeImageMedium" => new_deal.store_image.medium.url,
          "storeImageSmall" => new_deal.store_image.small.url,
          "refineryTerminal" => nil,
          "station" => {
            "name" => "Port Olisar",
            "slug" => "port-olisar"
          },
          "celestialObject" => {
            "name" => "Crusader",
            "slug" => "crusader",
            "type" => nil,
            "designation" => "2",
            "storeImage" => crusader.store_image.url,
            "storeImageLarge" => crusader.store_image.large.url,
            "storeImageMedium" => crusader.store_image.medium.url,
            "storeImageSmall" => crusader.store_image.small.url,
            "description" => nil,
            "habitable" => nil,
            "fairchanceact" => nil,
            "subType" => nil,
            "size" => nil,
            "danger" => nil,
            "economy" => nil,
            "population" => nil,
            "locationLabel" => crusader.location_label,
            "starsystem" => {
              "name" => "Stanton",
              "slug" => "stanton",
              "storeImage" => crusader.starsystem.store_image.url,
              "storeImageLarge" => crusader.starsystem.store_image.large.url,
              "storeImageMedium" => crusader.starsystem.store_image.medium.url,
              "storeImageSmall" => crusader.starsystem.store_image.small.url,
              "mapX" => nil,
              "mapY" => nil,
              "description" => nil,
              "type" => nil,
              "size" => nil,
              "population" => nil,
              "economy" => nil,
              "danger" => nil,
              "status" => nil,
              "locationLabel" => crusader.starsystem.location_label
            }
          },
          "createdAt" => new_deal.created_at.utc.iso8601,
          "updatedAt" => new_deal.updated_at.utc.iso8601
        }]
      end

      describe "without session" do
        it "should return list for index" do
          get "/api/v1/shops", as: :json

          assert_response :ok
          json = JSON.parse response.body

          assert_equal index_result, json
        end

        it "should return a single record for show" do
          get "/api/v1/stations/#{new_deal.station.slug}/shops/#{new_deal.slug}", as: :json

          assert_response :ok
          json = JSON.parse response.body

          assert_equal show_result, json
        end
      end

      describe "with session" do
        let(:data) { users :data }

        before do
          sign_in data
        end

        it "should return list for index" do
          get "/api/v1/shops", as: :json

          assert_response :ok
          json = JSON.parse response.body

          assert_equal index_result, json
        end

        it "should return a single record for show" do
          get "/api/v1/stations/#{new_deal.station.slug}/shops/#{new_deal.slug}", as: :json

          assert_response :ok
          json = JSON.parse response.body

          assert_equal show_result, json
        end
      end
    end
  end
end
