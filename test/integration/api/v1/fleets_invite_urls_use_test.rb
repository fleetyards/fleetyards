# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsInviteUrlsUseTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/use-invite" do
    post("Create Fleet Membership by Invite") do
      operationId "useFleetInvite"
      tags "FleetInviteUrls"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/FleetMembershipCreateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: []},
        {OpenId: []}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/FleetMember"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(400, "User is already a member of this fleet") do
        schema "$ref": "#/components/schemas/ValidationError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @author = create(:user)
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
    @invite_url = create(:fleet_invite_url, fleet: @fleet, user: @admin)
  end

  test "POST /fleets/use-invite creates a membership request" do
    sign_in @author

    assert_api_response :post, 201, body: {token: @invite_url.token} do
      assert_equal @author.username, parsed_body["username"]
      assert_equal "requested", parsed_body["status"]
    end

    notification = Notification.find_by(user: @admin, notification_type: "fleet_member_requested")
    assert_predicate notification, :present?
    assert_kind_of FleetMembership, notification.record
  end

  test "POST /fleets/use-invite returns 404 for unknown token" do
    sign_in @author

    assert_api_response :post, 404, body: {token: "unknown"}
  end

  test "POST /fleets/use-invite returns 400 for existing member" do
    sign_in @member

    assert_api_response :post, 400, body: {token: @invite_url.token}
  end

  test "POST /fleets/use-invite returns 401 when not signed in" do
    assert_api_response :post, 401, body: {token: @invite_url.token}
  end

  test "POST /fleets/use-invite with OAuth bearer token" do
    assert_api_response :post, 201,
      headers: oauth_headers_for(@author, scopes: ["public"]),
      body: {token: @invite_url.token}
  end
end
