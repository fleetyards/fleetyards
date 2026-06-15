# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetEventSignupsDestroyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleet-event-signups/{id}" do
    parameter name: "id", in: :path, schema: {type: :string}

    delete("Withdraw a member's signup (admin)") do
      operationId "destroyFleetEventSignup"
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

  test "DELETE /fleet-event-signups/:id admin withdraws a member's signup" do
    membership = @fleet.fleet_memberships.find_by(user: @member)
    signup = create(:fleet_event_signup, fleet_event_slot: @fleet_event_slot, fleet_membership: membership)
    sign_in @admin

    assert_api_response :delete, 204, path_params: {id: signup.id}
    assert_equal "withdrawn", signup.reload.status
  end

  test "DELETE /fleet-event-signups/:id with OAuth bearer token" do
    membership = @fleet.fleet_memberships.find_by(user: @member)
    signup = create(:fleet_event_signup, fleet_event_slot: @fleet_event_slot, fleet_membership: membership)

    assert_api_response :delete, 204,
      path_params: {id: signup.id},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"])
  end

  test "DELETE /fleet-event-signups/:id returns 401 for OAuth token with wrong scope" do
    membership = @fleet.fleet_memberships.find_by(user: @member)
    signup = create(:fleet_event_signup, fleet_event_slot: @fleet_event_slot, fleet_membership: membership)

    assert_api_response :delete, 401,
      path_params: {id: signup.id},
      headers: oauth_headers_for(@admin, scopes: ["public"])
  end

  test "DELETE /fleet-event-signups/:id returns 401 when not signed in" do
    membership = @fleet.fleet_memberships.find_by(user: @member)
    signup = create(:fleet_event_signup, fleet_event_slot: @fleet_event_slot, fleet_membership: membership)

    assert_api_response :delete, 401, path_params: {id: signup.id}
  end
end
