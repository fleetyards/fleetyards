# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::FleetsMembershipDeclineInvitationTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/membership/decline" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    put("Decline Membership") do
      operationId "declineFleetMembership"
      tags "FleetMembership"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: []},
        {OpenId: []}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @user = create(:user)
    @fleet = create(:fleet)
    @membership = create(:fleet_membership, fleet: @fleet, user: @user, aasm_state: :invited)
  end

  test "PUT /fleets/:slug/membership/decline declines the invitation" do
    sign_in @user

    assert_api_response :put, 200, path_params: {fleetSlug: @fleet.slug}, body: {}
  end

  test "PUT /fleets/:slug/membership/decline returns 404 for non-invited user" do
    sign_in create(:user)

    assert_api_response :put, 404, path_params: {fleetSlug: @fleet.slug}, body: {}
  end

  test "PUT /fleets/:slug/membership/decline returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: {fleetSlug: @fleet.slug}, body: {}
  end

  test "PUT /fleets/:slug/membership/decline with OAuth bearer token" do
    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@user, scopes: ["public"]),
      body: {}
  end
end
