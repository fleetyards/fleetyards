# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class VehiclesControllerTest < ActionDispatch::IntegrationTest
      describe "without session" do
        it "should render 403 for index" do
          get "/api/v1/vehicles", as: :json

          assert_response :unauthorized
          json = JSON.parse response.body

          assert_equal "unauthorized", json["code"]
        end

        it "should render 403 for quick-stats" do
          get "/api/v1/vehicles/quick-stats", as: :json

          assert_response :unauthorized
          json = JSON.parse response.body

          assert_equal "unauthorized", json["code"]
        end

        it "should render 200 for public quick-stats" do
          get "/api/v1/vehicles/data/quick-stats", as: :json

          assert_response :ok
          json = JSON.parse response.body

          expected = {
            "total" => 2,
            "classifications" => [{
              "name" => "explorer",
              "label" => "Explorer",
              "count" => 1
            }, {
              "name" => "multi_role",
              "label" => "Multi role",
              "count" => 1
            }],
            "groups" => []
          }

          assert_equal expected, json
        end

        it "should render 403 for hangar-items" do
          get "/api/v1/vehicles/hangar-items", as: :json

          assert_response :unauthorized
          json = JSON.parse response.body

          assert_equal "unauthorized", json["code"]
        end
      end

      describe "with session" do
        let(:data) { users :data }
        let(:explorer) { data.vehicles.includes(:model).find_by(models: {name: "600i"}) }
        let(:enterprise) { data.vehicles.includes(:model).find_by(models: {name: "Andromeda"}) }

        before do
          sign_in data
        end

        it "should return list for index" do
          get "/api/v1/vehicles", as: :json

          assert_response :ok
          json = JSON.parse response.body

          assert_equal 2, json.size
        end

        it "should return list for index when filtered" do
          query_params = {
            hangarGroupsIn: enterprise.hangar_groups.map(&:slug)
          }
          get "/api/v1/vehicles", params: {q: query_params.to_json}, as: :json

          assert_response :ok
          json = JSON.parse response.body

          assert_equal 1, json.size
        end

        it "should return counts for quick-stats" do
          get "/api/v1/vehicles/quick-stats", as: :json

          assert_response :ok
          json = JSON.parse response.body

          expected = {
            "total" => 2,
            "wishlistTotal" => 0,
            "classifications" => [{
              "name" => "explorer",
              "label" => "Explorer",
              "count" => 1
            }, {
              "name" => "multi_role",
              "label" => "Multi role",
              "count" => 1
            }],
            "groups" => [{
              "id" => "afe7ade2-7912-54a7-9bf7-9eb2415e8380",
              "slug" => "group-one",
              "count" => 1
            }, {
              "id" => "ae2759d9-a46f-5257-972f-430dbbce6fd3",
              "slug" => "group-two",
              "count" => 1
            }],
            "metrics" => {
              "totalMoney" => 625,
              "totalCredits" => 0,
              "totalMinCrew" => 5,
              "totalMaxCrew" => 10,
              "totalCargo" => 130
            }
          }

          assert_equal expected, json
        end

        it "should return counts for quick-stats" do
          get "/api/v1/vehicles/quick-stats", params: {q: '{ "classificationIn": ["combat"] }'}, as: :json

          assert_response :ok
          json = JSON.parse response.body

          expected = {
            "total" => 0,
            "wishlistTotal" => 0,
            "classifications" => [{
              "name" => "explorer",
              "label" => "Explorer",
              "count" => 0
            }, {
              "name" => "multi_role",
              "label" => "Multi role",
              "count" => 0
            }],
            "groups" => [{
              "id" => "afe7ade2-7912-54a7-9bf7-9eb2415e8380",
              "slug" => "group-one",
              "count" => 0
            }, {
              "id" => "ae2759d9-a46f-5257-972f-430dbbce6fd3",
              "slug" => "group-two",
              "count" => 0
            }],
            "metrics" => {
              "totalMoney" => 0,
              "totalCredits" => 0,
              "totalMinCrew" => 0,
              "totalMaxCrew" => 0,
              "totalCargo" => 0
            }
          }

          assert_equal expected, json
        end

        it "should render 200 for hangar-items" do
          get "/api/v1/vehicles/hangar-items", as: :json

          assert_response :ok
          json = JSON.parse response.body

          expected = %w[
            600i
            andromeda
          ]

          assert_equal expected, json
        end
      end
    end
  end
end
