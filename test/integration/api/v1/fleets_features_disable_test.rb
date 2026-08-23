# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsFeaturesDisableTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/features/{id}/disable" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "id", in: :path, schema: {type: :string}, description: "Feature name", required: true

    put("Disable Fleet Feature") do
      operationId "disableFleetFeature"
      tags "FleetFeatures"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetFeature"
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
    Flipper.enable_actor("FleetWideFeature", @fleet)
  end

  test "PUT /fleets/:slug/features/:id/disable disables the feature for the fleet" do
    sign_in @admin

    assert_api_response :put, 200, path_params: {fleetSlug: @fleet.slug, id: "FleetWideFeature"} do
      assert_not Flipper.enabled?("FleetWideFeature", @fleet)
      assert_not parsed_body["enabled"]
    end
  end

  test "PUT /fleets/:slug/features/:id/disable reports still enabled when the flag is on globally" do
    Flipper.enable("FleetWideFeature")
    sign_in @admin

    assert_api_response :put, 200, path_params: {fleetSlug: @fleet.slug, id: "FleetWideFeature"} do
      assert parsed_body["enabled"], "a fleet admin cannot switch off a global rollout"
    end
  end

  test "PUT /fleets/:slug/features/:id/disable with valid OAuth token" do
    token = create(:oauth_access_token, resource_owner_id: @admin.id, scopes: ["fleet"])

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, id: "FleetWideFeature"},
      headers: {"Authorization" => "Bearer #{token.token}"}
  end

  test "PUT /fleets/:slug/features/:id/disable returns 403 for a member without fleet:manage" do
    sign_in @member

    assert_api_response :put, 403, path_params: {fleetSlug: @fleet.slug, id: "FleetWideFeature"} do
      assert Flipper.enabled?("FleetWideFeature", @fleet)
    end
  end

  test "PUT /fleets/:slug/features/:id/disable returns 403 for a user-scoped feature" do
    Flipper.add("PersonalFeature")
    FeatureSetting.create!(feature_name: "PersonalFeature", self_service_user: true)
    sign_in @admin

    assert_api_response :put, 403, path_params: {fleetSlug: @fleet.slug, id: "PersonalFeature"}
  end

  test "PUT /fleets/:slug/features/:id/disable returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: {fleetSlug: @fleet.slug, id: "FleetWideFeature"}
  end

  test "PUT /fleets/:slug/features/:id/disable returns 404 for a fleet the user is not in" do
    sign_in create(:user)

    assert_api_response :put, 404, path_params: {fleetSlug: @fleet.slug, id: "FleetWideFeature"}
  end

  test "PUT /fleets/:slug/features/:id/disable returns 403 when a group the fleet is in enabled it" do
    with_flipper_group(:fleets, ->(actor, _context) { actor.respond_to?(:slug) }) do
      Flipper.enable_group("FleetWideFeature", :fleets)
      sign_in @admin

      assert_api_response :put, 403, path_params: {fleetSlug: @fleet.slug, id: "FleetWideFeature"} do
        assert Flipper.enabled?("FleetWideFeature", @fleet),
          "clearing the fleet's own gate would not take the group's grant away, so the API refuses " \
          "rather than reporting a change nobody will see"
      end
    end
  end
end
