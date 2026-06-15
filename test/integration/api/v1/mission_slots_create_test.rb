# frozen_string_literal: true

require "openapi_helper"

class Api::V1::MissionSlotsCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/mission-slots" do
    post("Create Mission Slot") do
      operationId "createMissionSlot"
      tags "Missions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/MissionSlotCreateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
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
  end

  test "POST /mission-slots creates a slot" do
    sign_in @admin

    assert_api_response :post, 201,
      body: {slottableType: "MissionTeam", slottableId: @team.id, title: "Pilot"} do
      assert_equal "Pilot", parsed_body["title"]
      assert_equal "MissionTeam", parsed_body["slottableType"]
    end
  end

  test "POST /mission-slots with OAuth bearer token" do
    assert_api_response :post, 201,
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {slottableType: "MissionTeam", slottableId: @team.id, title: "Pilot"}
  end

  test "POST /mission-slots returns 401 for OAuth token with wrong scope" do
    assert_api_response :post, 401,
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      body: {slottableType: "MissionTeam", slottableId: @team.id, title: "Pilot"}
  end

  test "POST /mission-slots returns 401 when not signed in" do
    assert_api_response :post, 401,
      body: {slottableType: "MissionTeam", slottableId: @team.id, title: "Pilot"}
  end
end
