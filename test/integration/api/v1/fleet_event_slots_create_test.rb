# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetEventSlotsCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleet-event-slots" do
    post("Create event slot") do
      operationId "createFleetEventSlot"
      tags "Fleet Event Slots"
      consumes "application/json"
      produces "application/json"

      request_body schema: {"$ref": "#/components/schemas/FleetEventSlotCreateInput"}, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/FleetEventSlot"
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
    @fleet_event = create(:fleet_event, fleet: @fleet, created_by: @admin)
    @team = create(:fleet_event_team, fleet_event: @fleet_event)
  end

  test "POST /fleet-event-slots creates a slot" do
    sign_in @admin

    assert_api_response :post, 201,
      body: {slottableType: "FleetEventTeam", slottableId: @team.id, title: "Pilot"}
  end

  test "POST /fleet-event-slots with OAuth bearer token" do
    assert_api_response :post, 201,
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {slottableType: "FleetEventTeam", slottableId: @team.id, title: "Pilot"}
  end

  test "POST /fleet-event-slots returns 401 for OAuth token with wrong scope" do
    assert_api_response :post, 401,
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      body: {slottableType: "FleetEventTeam", slottableId: @team.id, title: "Pilot"}
  end

  test "POST /fleet-event-slots returns 401 when not signed in" do
    assert_api_response :post, 401,
      body: {slottableType: "FleetEventTeam", slottableId: @team.id, title: "Pilot"}
  end
end
