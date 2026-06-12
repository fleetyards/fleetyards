# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::FleetsInviteUrlsDestroyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/invite-urls/{token}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "token", in: :path, schema: {type: :string}, description: "Invite Url Token"

    delete("Remove Fleet Invite Url") do
      operationId "destroyFleetInviteUrl"
      tags "FleetInviteUrls"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(204, "successful")

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
    @invite_url = create(:fleet_invite_url, fleet: @fleet, user: @admin)
  end

  test "DELETE /fleets/:slug/invite-urls/:token removes the invite url" do
    sign_in @admin

    assert_api_response :delete, 204, path_params: {fleetSlug: @fleet.slug, token: @invite_url.token}
  end

  test "DELETE /fleets/:slug/invite-urls/:token returns 404 for unknown fleet" do
    sign_in @admin

    assert_api_response :delete, 404, path_params: {fleetSlug: "unknown-fleet", token: @invite_url.token}
  end

  test "DELETE /fleets/:slug/invite-urls/:token returns 404 for unknown token" do
    sign_in @admin

    assert_api_response :delete, 404, path_params: {fleetSlug: @fleet.slug, token: "unknown-token"}
  end

  test "DELETE /fleets/:slug/invite-urls/:token returns 403 for non-admin member" do
    sign_in @member

    assert_api_response :delete, 403, path_params: {fleetSlug: @fleet.slug, token: @invite_url.token}
  end

  test "DELETE /fleets/:slug/invite-urls/:token returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: {fleetSlug: @fleet.slug, token: @invite_url.token}
  end

  test "DELETE /fleets/:slug/invite-urls/:token with OAuth bearer token" do
    assert_api_response :delete, 204,
      path_params: {fleetSlug: @fleet.slug, token: @invite_url.token},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"])
  end
end
