# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetEventSignupsSignupTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleet-event-slots/{id}/signup" do
    parameter name: "id", in: :path, schema: {type: :string}

    post("Sign up for slot") do
      operationId "signupFleetEventSlot"
      tags "Fleet Event Signups"
      consumes "application/json"
      produces "application/json"

      request_body schema: {"$ref": "#/components/schemas/FleetEventSignupCreateInput"}, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/FleetEventSignup"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    patch("Update own signup") do
      operationId "updateFleetEventSignup"
      tags "Fleet Event Signups"
      consumes "application/json"
      produces "application/json"

      request_body schema: {"$ref": "#/components/schemas/FleetEventSignupUpdateInput"}, required: true

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

    delete("Withdraw own signup") do
      operationId "withdrawFleetEventSignup"
      tags "Fleet Event Signups"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(204, "successful") do
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
  end

  test "POST /fleet-event-slots/:id/signup creates a signup" do
    sign_in @member

    assert_api_response :post, 201,
      path_params: {id: @fleet_event_slot.id},
      body: {status: "confirmed", notes: "Ready"} do
      assert_equal "confirmed", parsed_body["status"]
      assert_equal "Ready", parsed_body["notes"]
    end
  end

  test "POST /fleet-event-slots/:id/signup with OAuth bearer token" do
    assert_api_response :post, 201,
      path_params: {id: @fleet_event_slot.id},
      headers: oauth_headers_for(@member, scopes: ["fleet", "fleet:write"]),
      body: {status: "confirmed", notes: "Ready"}
  end

  test "POST /fleet-event-slots/:id/signup returns 401 for OAuth token with wrong scope" do
    assert_api_response :post, 401,
      path_params: {id: @fleet_event_slot.id},
      headers: oauth_headers_for(@member, scopes: ["public"]),
      body: {status: "confirmed", notes: "Ready"}
  end

  test "POST /fleet-event-slots/:id/signup returns 401 when not signed in" do
    assert_api_response :post, 401,
      path_params: {id: @fleet_event_slot.id},
      body: {status: "confirmed", notes: "Ready"}
  end

  test "PATCH /fleet-event-slots/:id/signup updates own signup" do
    membership = @fleet.fleet_memberships.find_by(user: @member)
    create(:fleet_event_signup, fleet_event_slot: @fleet_event_slot, fleet_membership: membership, status: "pending")
    sign_in @member

    assert_api_response :patch, 200,
      path_params: {id: @fleet_event_slot.id},
      body: {status: "confirmed"} do
      assert_equal "confirmed", parsed_body["status"]
    end
  end

  test "PATCH /fleet-event-slots/:id/signup with OAuth bearer token" do
    membership = @fleet.fleet_memberships.find_by(user: @member)
    create(:fleet_event_signup, fleet_event_slot: @fleet_event_slot, fleet_membership: membership, status: "pending")

    assert_api_response :patch, 200,
      path_params: {id: @fleet_event_slot.id},
      headers: oauth_headers_for(@member, scopes: ["fleet", "fleet:write"]),
      body: {status: "confirmed"}
  end

  test "PATCH /fleet-event-slots/:id/signup returns 401 for OAuth token with wrong scope" do
    membership = @fleet.fleet_memberships.find_by(user: @member)
    create(:fleet_event_signup, fleet_event_slot: @fleet_event_slot, fleet_membership: membership, status: "pending")

    assert_api_response :patch, 401,
      path_params: {id: @fleet_event_slot.id},
      headers: oauth_headers_for(@member, scopes: ["public"]),
      body: {status: "confirmed"}
  end

  test "PATCH /fleet-event-slots/:id/signup returns 401 when not signed in" do
    membership = @fleet.fleet_memberships.find_by(user: @member)
    create(:fleet_event_signup, fleet_event_slot: @fleet_event_slot, fleet_membership: membership, status: "pending")

    assert_api_response :patch, 401,
      path_params: {id: @fleet_event_slot.id},
      body: {status: "confirmed"}
  end

  test "DELETE /fleet-event-slots/:id/signup withdraws own signup" do
    membership = @fleet.fleet_memberships.find_by(user: @member)
    create(:fleet_event_signup, fleet_event_slot: @fleet_event_slot, fleet_membership: membership, status: "confirmed")
    sign_in @member

    assert_api_response :delete, 204, path_params: {id: @fleet_event_slot.id}
  end

  test "DELETE /fleet-event-slots/:id/signup with OAuth bearer token" do
    membership = @fleet.fleet_memberships.find_by(user: @member)
    create(:fleet_event_signup, fleet_event_slot: @fleet_event_slot, fleet_membership: membership, status: "confirmed")

    assert_api_response :delete, 204,
      path_params: {id: @fleet_event_slot.id},
      headers: oauth_headers_for(@member, scopes: ["fleet", "fleet:write"])
  end

  test "DELETE /fleet-event-slots/:id/signup returns 401 for OAuth token with wrong scope" do
    membership = @fleet.fleet_memberships.find_by(user: @member)
    create(:fleet_event_signup, fleet_event_slot: @fleet_event_slot, fleet_membership: membership, status: "confirmed")

    assert_api_response :delete, 401,
      path_params: {id: @fleet_event_slot.id},
      headers: oauth_headers_for(@member, scopes: ["public"])
  end

  test "DELETE /fleet-event-slots/:id/signup returns 401 when not signed in" do
    membership = @fleet.fleet_memberships.find_by(user: @member)
    create(:fleet_event_signup, fleet_event_slot: @fleet_event_slot, fleet_membership: membership, status: "confirmed")

    assert_api_response :delete, 401, path_params: {id: @fleet_event_slot.id}
  end
end
