# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::FleetsShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{slug}" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "slug"

    get("Fleet Detail") do
      operationId "fleet"
      tags "Fleets"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Fleet"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @admin = create(:user, :with_rsi_handle)
    @member = create(:user)
    @fleet = create(:fleet, :with_description, :with_logo, :with_background_image, :with_social_links, admins: [@admin], members: [@member])
  end

  test "GET /fleets/:slug returns the fleet for admin" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {slug: @fleet.slug}
  end

  test "GET /fleets/:slug returns the fleet for member" do
    sign_in @member

    assert_api_response :get, 200, path_params: {slug: @fleet.slug}
  end

  test "GET /fleets/:slug returns 404 for unknown slug" do
    sign_in @admin

    assert_api_response :get, 404, path_params: {slug: "unknown-fleet"}
  end

  test "GET /fleets/:slug returns 403 for an unrelated user" do
    sign_in create(:user)

    assert_api_response :get, 403, path_params: {slug: @fleet.slug}
  end

  test "GET /fleets/:slug returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {slug: @fleet.slug}
  end

  test "GET /fleets/:slug with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {slug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end

  test "GET /fleets/:slug returns 401 for OAuth token with wrong scope" do
    assert_api_response :get, 401,
      path_params: {slug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"])
  end
end
