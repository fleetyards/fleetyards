# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class CelestialObjectsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @request.host = "api.fleetyards.test"
      end

      let(:crusader) { celestial_objects :crusader }
      let(:hurston) { celestial_objects :hurston }
      let(:yela) { celestial_objects :yela }
      let(:daymar) { celestial_objects :daymar }
      let(:index_result) do
        [{
          "name" => "Hurston",
          "slug" => "hurston",
          "type" => nil,
          "designation" => "1",
          "media" => {
            "storeImage" => nil
          },
          "storeImage" => hurston.store_image.url,
          "storeImageLarge" => hurston.store_image.large.url,
          "storeImageMedium" => hurston.store_image.medium.url,
          "storeImageSmall" => hurston.store_image.small.url,
          "description" => nil,
          "habitable" => nil,
          "fairchanceact" => nil,
          "subType" => nil,
          "size" => nil,
          "danger" => nil,
          "economy" => nil,
          "population" => nil,
          "locationLabel" => hurston.location_label,
          "starsystem" => {
            "name" => "Stanton",
            "slug" => "stanton",
            "media" => {
              "storeImage" => nil
            },
            "storeImage" => hurston.starsystem.store_image.url,
            "storeImageLarge" => hurston.starsystem.store_image.large.url,
            "storeImageMedium" => hurston.starsystem.store_image.medium.url,
            "storeImageSmall" => hurston.starsystem.store_image.small.url,
            "mapX" => nil,
            "mapY" => nil,
            "description" => nil,
            "type" => nil,
            "size" => nil,
            "population" => nil,
            "economy" => nil,
            "danger" => nil,
            "status" => nil,
            "locationLabel" => hurston.starsystem.location_label
          },
          "moons" => [],
          "createdAt" => hurston.created_at.utc.iso8601,
          "updatedAt" => hurston.updated_at.utc.iso8601
        }, {
          "name" => "Crusader",
          "slug" => "crusader",
          "type" => nil,
          "designation" => "2",
          "media" => {
            "storeImage" => nil
          },
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
            "media" => {
              "storeImage" => nil
            },
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
          },
          "moons" => [{
            "name" => "Yela",
            "slug" => "yela",
            "type" => nil,
            "designation" => "3",
            "media" => {
              "storeImage" => nil
            },
            "storeImage" => crusader.moons.first.store_image.url,
            "storeImageLarge" => crusader.moons.first.store_image.large.url,
            "storeImageMedium" => crusader.moons.first.store_image.medium.url,
            "storeImageSmall" => crusader.moons.first.store_image.small.url,
            "description" => nil,
            "habitable" => nil,
            "fairchanceact" => nil,
            "subType" => nil,
            "size" => nil,
            "danger" => nil,
            "economy" => nil,
            "population" => nil,
            "locationLabel" => crusader.moons.first.location_label,
            "parent" => {
              "name" => "Crusader",
              "slug" => "crusader",
              "type" => nil,
              "designation" => "2",
              "media" => {
                "storeImage" => nil
              },
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
                "media" => {
                  "storeImage" => nil
                },
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
              "media" => {
                "storeImage" => nil
              },
              "storeImage" => yela.starsystem.store_image.url,
              "storeImageLarge" => yela.starsystem.store_image.large.url,
              "storeImageMedium" => yela.starsystem.store_image.medium.url,
              "storeImageSmall" => yela.starsystem.store_image.small.url,
              "mapX" => nil,
              "mapY" => nil,
              "description" => nil,
              "type" => nil,
              "size" => nil,
              "population" => nil,
              "economy" => nil,
              "danger" => nil,
              "status" => nil,
              "locationLabel" => yela.starsystem.location_label
            }
          }, {
            "name" => "Daymar",
            "slug" => "daymar",
            "type" => nil,
            "designation" => "4",
            "media" => {
              "storeImage" => nil
            },
            "storeImage" => crusader.moons.last.store_image.url,
            "storeImageLarge" => crusader.moons.last.store_image.large.url,
            "storeImageMedium" => crusader.moons.last.store_image.medium.url,
            "storeImageSmall" => crusader.moons.last.store_image.small.url,
            "description" => nil,
            "habitable" => nil,
            "fairchanceact" => nil,
            "subType" => nil,
            "size" => nil,
            "danger" => nil,
            "economy" => nil,
            "population" => nil,
            "locationLabel" => crusader.moons.last.location_label,
            "parent" => {
              "name" => "Crusader",
              "slug" => "crusader",
              "type" => nil,
              "designation" => "2",
              "media" => {
                "storeImage" => nil
              },
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
                "media" => {
                  "storeImage" => nil
                },
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
              "media" => {
                "storeImage" => nil
              },
              "storeImage" => daymar.starsystem.store_image.url,
              "storeImageLarge" => daymar.starsystem.store_image.large.url,
              "storeImageMedium" => daymar.starsystem.store_image.medium.url,
              "storeImageSmall" => daymar.starsystem.store_image.small.url,
              "mapX" => nil,
              "mapY" => nil,
              "description" => nil,
              "type" => nil,
              "size" => nil,
              "population" => nil,
              "economy" => nil,
              "danger" => nil,
              "status" => nil,
              "locationLabel" => daymar.starsystem.location_label
            }
          }],
          "createdAt" => crusader.created_at.utc.iso8601,
          "updatedAt" => crusader.updated_at.utc.iso8601
        }, {
          "name" => "Yela",
          "slug" => "yela",
          "type" => nil,
          "designation" => "3",
          "media" => {
            "storeImage" => nil
          },
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
            "media" => {
              "storeImage" => nil
            },
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
              "media" => {
                "storeImage" => nil
              },
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
            "media" => {
              "storeImage" => nil
            },
            "storeImage" => yela.starsystem.store_image.url,
            "storeImageLarge" => yela.starsystem.store_image.large.url,
            "storeImageMedium" => yela.starsystem.store_image.medium.url,
            "storeImageSmall" => yela.starsystem.store_image.small.url,
            "mapX" => nil,
            "mapY" => nil,
            "description" => nil,
            "type" => nil,
            "size" => nil,
            "population" => nil,
            "economy" => nil,
            "danger" => nil,
            "status" => nil,
            "locationLabel" => yela.starsystem.location_label
          },
          "moons" => [],
          "createdAt" => yela.created_at.utc.iso8601,
          "updatedAt" => yela.updated_at.utc.iso8601
        }, {
          "name" => "Daymar",
          "slug" => "daymar",
          "type" => nil,
          "designation" => "4",
          "media" => {
            "storeImage" => nil
          },
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
            "media" => {
              "storeImage" => nil
            },
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
              "media" => {
                "storeImage" => nil
              },
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
            "media" => {
              "storeImage" => nil
            },
            "storeImage" => daymar.starsystem.store_image.url,
            "storeImageLarge" => daymar.starsystem.store_image.large.url,
            "storeImageMedium" => daymar.starsystem.store_image.medium.url,
            "storeImageSmall" => daymar.starsystem.store_image.small.url,
            "mapX" => nil,
            "mapY" => nil,
            "description" => nil,
            "type" => nil,
            "size" => nil,
            "population" => nil,
            "economy" => nil,
            "danger" => nil,
            "status" => nil,
            "locationLabel" => daymar.starsystem.location_label
          },
          "moons" => [],
          "createdAt" => daymar.created_at.utc.iso8601,
          "updatedAt" => daymar.updated_at.utc.iso8601
        }]
      end
      let(:show_result) do
        {
          "name" => "Crusader",
          "slug" => "crusader",
          "type" => nil,
          "designation" => "2",
          "media" => {
            "storeImage" => nil
          },
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
            "media" => {
              "storeImage" => nil
            },
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
          },
          "moons" => [{
            "name" => "Yela",
            "slug" => "yela",
            "type" => nil,
            "designation" => "3",
            "media" => {
              "storeImage" => nil
            },
            "storeImage" => crusader.moons.first.store_image.url,
            "storeImageLarge" => crusader.moons.first.store_image.large.url,
            "storeImageMedium" => crusader.moons.first.store_image.medium.url,
            "storeImageSmall" => crusader.moons.first.store_image.small.url,
            "description" => nil,
            "habitable" => nil,
            "fairchanceact" => nil,
            "subType" => nil,
            "size" => nil,
            "danger" => nil,
            "economy" => nil,
            "population" => nil,
            "locationLabel" => crusader.moons.first.location_label,
            "parent" => {
              "name" => "Crusader",
              "slug" => "crusader",
              "type" => nil,
              "designation" => "2",
              "media" => {
                "storeImage" => nil
              },
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
                "media" => {
                  "storeImage" => nil
                },
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
              "media" => {
                "storeImage" => nil
              },
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
          }, {
            "name" => "Daymar",
            "slug" => "daymar",
            "type" => nil,
            "designation" => "4",
            "media" => {
              "storeImage" => nil
            },
            "storeImage" => crusader.moons.last.store_image.url,
            "storeImageLarge" => crusader.moons.last.store_image.large.url,
            "storeImageMedium" => crusader.moons.last.store_image.medium.url,
            "storeImageSmall" => crusader.moons.last.store_image.small.url,
            "description" => nil,
            "habitable" => nil,
            "fairchanceact" => nil,
            "subType" => nil,
            "size" => nil,
            "danger" => nil,
            "economy" => nil,
            "population" => nil,
            "locationLabel" => crusader.moons.last.location_label,
            "parent" => {
              "name" => "Crusader",
              "slug" => "crusader",
              "type" => nil,
              "designation" => "2",
              "media" => {
                "storeImage" => nil
              },
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
                "media" => {
                  "storeImage" => nil
                },
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
              "media" => {
                "storeImage" => nil
              },
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
          }],
          "createdAt" => crusader.created_at.utc.iso8601,
          "updatedAt" => crusader.updated_at.utc.iso8601
        }
      end

      describe "without session" do
        it "should return list for index" do
          get "/v1/celestial-objects", as: :json, host: "api.fleetyards.test"

          assert_response :ok
          json = JSON.parse response.body

          assert_equal index_result, json
        end

        it "should return a single record for show" do
          get "/v1/celestial-objects/#{crusader.slug}", as: :json

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
          get "/v1/celestial-objects", as: :json

          assert_response :ok
          json = JSON.parse response.body

          assert_equal index_result, json
        end

        it "should return a single record for show" do
          get "/v1/celestial-objects/#{crusader.slug}", as: :json

          assert_response :ok
          json = JSON.parse response.body

          assert_equal show_result, json
        end
      end
    end
  end
end
