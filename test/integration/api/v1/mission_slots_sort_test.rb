# frozen_string_literal: true

require "openapi_helper"

class Api::V1::MissionSlotsSortTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/mission-slots/sort" do
    put("Sort Mission Slots") do
      operationId "sortMissionSlots"
      tags "Missions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/MissionSlotSortInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema type: :object, properties: {success: {type: :boolean}}
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
    @slots = create_list(:mission_slot, 3, slottable: @team)
  end

  test "PUT /mission-slots/sort updates positions" do
    sign_in @admin

    assert_api_response :put, 200,
      body: {slottableType: "MissionTeam", slottableId: @team.id, sorting: @slots.reverse.map(&:id)}

    @slots.reverse.each_with_index do |slot, index|
      assert_equal index, slot.reload.position
    end
  end

  test "PUT /mission-slots/sort with OAuth bearer token" do
    assert_api_response :put, 200,
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {slottableType: "MissionTeam", slottableId: @team.id, sorting: @slots.reverse.map(&:id)}
  end

  test "PUT /mission-slots/sort returns 401 for OAuth token with wrong scope" do
    assert_api_response :put, 401,
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      body: {slottableType: "MissionTeam", slottableId: @team.id, sorting: @slots.reverse.map(&:id)}
  end

  test "PUT /mission-slots/sort returns 401 when not signed in" do
    assert_api_response :put, 401,
      body: {slottableType: "MissionTeam", slottableId: @team.id, sorting: @slots.reverse.map(&:id)}
  end
end
