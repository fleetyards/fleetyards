# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::FleetsMembersDestroyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/members/{username}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "username", in: :path, schema: {type: :string}, description: "username"

    delete("Remove Fleet Member") do
      operationId "destroyFleetMember"
      tags "FleetMembers"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(204, "successful")

      response(401, "Without authentication") do
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
    @another_member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member, @another_member])
  end

  test "DELETE /fleets/:slug/members/:username removes the member" do
    sign_in @admin

    assert_api_response :delete, 204, path_params: {fleetSlug: @fleet.slug, username: @member.username}
  end

  test "DELETE /fleets/:slug/members/:username returns 404 for unknown member" do
    sign_in @admin

    assert_api_response :delete, 404, path_params: {fleetSlug: @fleet.slug, username: "unknown"}
  end

  test "DELETE /fleets/:slug/members/:username returns 403 for a non-admin fleet member" do
    sign_in @another_member

    assert_api_response :delete, 403, path_params: {fleetSlug: @fleet.slug, username: @member.username}
  end

  test "DELETE /fleets/:slug/members/:username lets a member remove their own membership" do
    sign_in @member

    assert_api_response :delete, 204, path_params: {fleetSlug: @fleet.slug, username: @member.username}
  end

  test "DELETE /fleets/:slug/members/:username returns 403 when a non-owner tries to remove an admin" do
    sign_in @another_member

    assert_api_response :delete, 403, path_params: {fleetSlug: @fleet.slug, username: @admin.username}
  end

  test "DELETE /fleets/:slug/members/:username returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: {fleetSlug: @fleet.slug, username: @member.username}
  end

  test "DELETE /fleets/:slug/members/:username with OAuth bearer token" do
    assert_api_response :delete, 204,
      path_params: {fleetSlug: @fleet.slug, username: @member.username},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"])
  end
end
