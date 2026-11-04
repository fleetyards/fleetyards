# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsMembershipWithdrawTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/membership/withdraw" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    put("Withdraw Join Request") do
      operationId "withdrawFleetMembership"
      tags "FleetMembership"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::StandardMessage
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:user)
    @fleet = create(:fleet)
    @membership = create(:fleet_membership, :requested, fleet: @fleet, user: @user)
  end

  test "PUT /fleets/:slug/membership/withdraw removes the request and allows a new one" do
    sign_in @user

    assert_api_response :put, 200, path_params: {fleetSlug: @fleet.slug}, body: {}

    assert_predicate @membership.reload, :discarded?

    get "/api/v1/fleets/invites"

    assert_empty parsed_body
    assert_predicate create(:fleet_membership, :requested, fleet: @fleet, user: @user), :persisted?
  end

  test "PUT /fleets/:slug/membership/withdraw keeps a request that was accepted in the meantime" do
    @membership.accept_request!
    sign_in @user

    assert_api_response :put, 400, path_params: {fleetSlug: @fleet.slug}, body: {}

    assert_predicate @membership.reload, :kept?
    assert_predicate @membership, :accepted?
  end

  test "PUT /fleets/:slug/membership/withdraw does not touch an invitation" do
    invited = create(:user)
    invitation = create(:fleet_membership, :invited, fleet: @fleet, user: invited)
    sign_in invited

    assert_api_response :put, 400, path_params: {fleetSlug: @fleet.slug}, body: {}

    assert_predicate invitation.reload, :kept?
  end

  test "PUT /fleets/:slug/membership/withdraw returns 404 without a membership" do
    sign_in create(:user)

    assert_api_response :put, 404, path_params: {fleetSlug: @fleet.slug}, body: {}
  end

  test "PUT /fleets/:slug/membership/withdraw returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: {fleetSlug: @fleet.slug}, body: {}
  end

  test "PUT /fleets/:slug/membership/withdraw with OAuth bearer token" do
    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug},
      body: {},
      headers: oauth_headers_for(@user, scopes: ["fleet", "fleet:write"])
  end
end
