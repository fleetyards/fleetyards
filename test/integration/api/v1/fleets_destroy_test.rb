# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsDestroyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{slug}" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "slug"

    delete("Destroy Fleet") do
      operationId "destroyFleet"
      tags "Fleets"
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

      response(403, "You are not the owner of this Fleet") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
  end

  test "DELETE /fleets/:slug destroys the fleet for the admin" do
    sign_in @admin

    assert_api_response :delete, 204, path_params: {slug: @fleet.slug}
  end

  test "DELETE /fleets/:slug returns 404 for unknown slug" do
    sign_in @admin

    assert_api_response :delete, 404, path_params: {slug: "unknown-model"}
  end

  test "DELETE /fleets/:slug returns 403 for a member" do
    sign_in @member

    assert_api_response :delete, 403, path_params: {slug: @fleet.slug}
  end

  test "DELETE /fleets/:slug returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: {slug: @fleet.slug}
  end

  test "DELETE /fleets/:slug with OAuth bearer token" do
    assert_api_response :delete, 204,
      path_params: {slug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"])
  end

  test "DELETE /fleets/:slug returns 401 for OAuth token with wrong scope" do
    assert_api_response :delete, 401,
      path_params: {slug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"])
  end
end
