# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::FleetsMembershipTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  # destroy, show, update declared in alphabetical spec-file order so the
  # generated DELETE/GET/PUT YAML order matches the original schema.

  api_path "/fleets/{fleetSlug}/membership" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    delete("Leave Fleet") do
      operationId "leaveFleet"
      tags "FleetMembership"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: []},
        {OpenId: []}
      ]

      response(204, "successful")

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    get("Fleet Membership Detail") do
      operationId "fleetMembership"
      tags "FleetMembership"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: []},
        {OpenId: []}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetMember"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    put("Update Membership") do
      operationId "updateFleetMembership"
      tags "FleetMembership"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/FleetMembershipUpdateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: []},
        {OpenId: []}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetMember"
      end

      response(404, "Fleet for this slug and user does not exist") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @member = create(:user, :with_rsi_handle, :with_avatar)
    @fleet = create(:fleet, :with_description)
    @membership = create(:fleet_membership, fleet: @fleet, user: @member)
  end

  # DELETE /fleets/:slug/membership
  test "DELETE /fleets/:slug/membership leaves the fleet" do
    sign_in @member

    assert_api_response :delete, 204, path_params: {fleetSlug: @fleet.slug}
  end

  test "DELETE /fleets/:slug/membership returns 404 for unknown fleet" do
    sign_in @member

    assert_api_response :delete, 404, path_params: {fleetSlug: "unknown-fleet"}
  end

  test "DELETE /fleets/:slug/membership returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: {fleetSlug: @fleet.slug}
  end

  test "DELETE /fleets/:slug/membership with OAuth bearer token" do
    assert_api_response :delete, 204,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@member, scopes: ["public"])
  end

  # GET /fleets/:slug/membership
  test "GET /fleets/:slug/membership returns the membership" do
    sign_in @member

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal @member.username, parsed_body["username"]
    end
  end

  test "GET /fleets/:slug/membership returns 404 for unknown fleet" do
    sign_in @member

    assert_api_response :get, 404, path_params: {fleetSlug: "unknown-fleet"}
  end

  test "GET /fleets/:slug/membership returns 404 for user without membership" do
    sign_in create(:user)

    assert_api_response :get, 404, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/membership returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/membership with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@member, scopes: ["public"])
  end

  # PUT /fleets/:slug/membership
  test "PUT /fleets/:slug/membership updates the membership" do
    sign_in @member

    assert_api_response :put, 200, path_params: {fleetSlug: @fleet.slug}, body: {primary: true}
  end

  test "PUT /fleets/:slug/membership returns 404 for unknown fleet" do
    sign_in @member

    assert_api_response :put, 404, path_params: {fleetSlug: "unknown-fleet"}, body: {primary: true}
  end

  test "PUT /fleets/:slug/membership returns 404 for user without membership" do
    sign_in create(:user)

    assert_api_response :put, 404, path_params: {fleetSlug: @fleet.slug}, body: {primary: true}
  end

  test "PUT /fleets/:slug/membership returns 400 for an invalid body" do
    sign_in @member

    assert_api_response :put, 400, path_params: {fleetSlug: @fleet.slug}, body: {shipsFilter: "unknown"}
  end

  test "PUT /fleets/:slug/membership returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: {fleetSlug: @fleet.slug}, body: {primary: true}
  end

  test "PUT /fleets/:slug/membership with OAuth bearer token" do
    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@member, scopes: ["public"]),
      body: {primary: true}
  end
end
