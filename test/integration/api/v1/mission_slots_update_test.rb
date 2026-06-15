# frozen_string_literal: true

require "openapi_helper"

class Api::V1::MissionSlotsUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/mission-slots/{id}" do
    parameter name: "id", in: :path, schema: {type: :string}

    put("Update Mission Slot") do
      operationId "updateMissionSlot"
      tags "Missions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/MissionSlotUpdateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/MissionSlot"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Flipper.enable("mission_builder")
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
    @mission = create(:mission, fleet: @fleet, created_by: @admin)
    @team = create(:mission_team, mission: @mission)
    @slot = create(:mission_slot, slottable: @team)
  end

  test "PUT /mission-slots/:id updates the slot" do
    sign_in @admin

    assert_api_response :put, 200, path_params: {id: @slot.id}, body: {title: "Co-Pilot"} do
      assert_equal "Co-Pilot", parsed_body["title"]
    end
  end

  test "PUT /mission-slots/:id with OAuth bearer token" do
    assert_api_response :put, 200,
      path_params: {id: @slot.id},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {title: "Co-Pilot"}
  end

  test "PUT /mission-slots/:id returns 401 for OAuth token with wrong scope" do
    assert_api_response :put, 401,
      path_params: {id: @slot.id},
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      body: {title: "Co-Pilot"}
  end

  test "PUT /mission-slots/:id returns 401 when not signed in" do
    assert_api_response :put, 401,
      path_params: {id: @slot.id},
      body: {title: "Co-Pilot"}
  end
end
