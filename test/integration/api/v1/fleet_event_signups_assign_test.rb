# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetEventSignupsAssignTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleet-event-signups/{id}/assign" do
    parameter name: "id", in: :path, schema: {type: :string}

    patch("Admin: assign or update a signup") do
      operationId "assignFleetEventSignup"
      tags "Fleet Event Signups"
      consumes "application/json"
      produces "application/json"

      request_body schema: {"$ref": "#/components/schemas/FleetEventSignupAssignInput"}, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetEventSignup"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Flipper.enable("mission_builder")
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
    @fleet_event = create(:fleet_event, :open, fleet: @fleet, created_by: @admin)
    @fleet_event_team = create(:fleet_event_team, fleet_event: @fleet_event)
    @fleet_event_slot = create(:fleet_event_slot, slottable: @fleet_event_team)
    @other_slot = create(:fleet_event_slot, slottable: @fleet_event_team)

    membership = @fleet.fleet_memberships.find_by(user: @member)
    @signup = create(:fleet_event_signup,
      fleet_event: @fleet_event,
      fleet_event_slot: nil,
      fleet_membership: membership,
      status: "interested")
  end

  test "PATCH /fleet-event-signups/:id/assign assigns slot and status" do
    sign_in @admin

    assert_api_response :patch, 200,
      path_params: {id: @signup.id},
      body: {fleetEventSlotId: @other_slot.id, status: "confirmed"} do
      assert_equal "confirmed", parsed_body["status"]
      assert_equal @other_slot.id, parsed_body["fleetEventSlotId"]
    end
  end

  test "PATCH /fleet-event-signups/:id/assign with OAuth bearer token" do
    assert_api_response :patch, 200,
      path_params: {id: @signup.id},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {fleetEventSlotId: @other_slot.id, status: "confirmed"}
  end

  test "PATCH /fleet-event-signups/:id/assign returns 401 for OAuth token with wrong scope" do
    assert_api_response :patch, 401,
      path_params: {id: @signup.id},
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      body: {fleetEventSlotId: @other_slot.id, status: "confirmed"}
  end

  test "PATCH /fleet-event-signups/:id/assign returns 401 when not signed in" do
    assert_api_response :patch, 401,
      path_params: {id: @signup.id},
      body: {fleetEventSlotId: @other_slot.id, status: "confirmed"}
  end
end
