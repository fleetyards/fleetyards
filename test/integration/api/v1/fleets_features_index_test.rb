# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsFeaturesIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/features" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Fleet Features List") do
      operationId "fleetFeatures"
      tags "FleetFeatures"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/FleetFeature"}
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
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])

    Flipper.add("FleetWideFeature")
    FeatureSetting.create!(feature_name: "FleetWideFeature", self_service_user: true, self_service_fleet: true)
  end

  test "GET /fleets/:slug/features lists the fleet-scoped features with their state" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal [{"name" => "FleetWideFeature", "enabled" => false}], parsed_body
    end
  end

  test "GET /fleets/:slug/features reports a feature enabled for the fleet actor" do
    Flipper.enable_actor("FleetWideFeature", @fleet)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert parsed_body.first["enabled"]
    end
  end

  test "GET /fleets/:slug/features ignores a member's own gate on the flag" do
    Flipper.enable_actor("FleetWideFeature", @admin)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_not parsed_body.first["enabled"],
        "the tab reports the fleet's state, not the viewer's"
    end
  end

  test "GET /fleets/:slug/features excludes user-scoped features" do
    Flipper.add("PersonalFeature")
    FeatureSetting.create!(feature_name: "PersonalFeature", self_service_user: true)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal %w[FleetWideFeature], parsed_body.map { |feature| feature["name"] }
    end
  end

  test "GET /fleets/:slug/features excludes globally enabled features" do
    Flipper.enable("FleetWideFeature")
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_empty parsed_body, "nothing left for a fleet admin to decide"
    end
  end

  test "GET /fleets/:slug/features with valid OAuth token" do
    token = create(:oauth_access_token, resource_owner_id: @admin.id, scopes: ["fleet"])

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: {"Authorization" => "Bearer #{token.token}"}
  end

  test "GET /fleets/:slug/features returns 403 for a member without fleet:manage" do
    sign_in @member

    assert_api_response :get, 403, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/features returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/features returns 404 for a fleet the user is not in" do
    sign_in create(:user)

    assert_api_response :get, 404, path_params: {fleetSlug: @fleet.slug}
  end
end
