# frozen_string_literal: true

require "openapi_helper"

class Api::V1::UserFeaturesIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/user-features" do
    get("User Feature Flags") do
      operationId "userFeatures"
      tags "UserFeatures"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["profile:write"]},
        {OpenId: ["profile:write"]}
      ]

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/UserFeature"}
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @user = create(:user)
    Flipper.add("TestFeature")
    FeatureSetting.create!(feature_name: "TestFeature", self_service_user: true)
  end

  test "GET /user-features lists self-service features for the signed-in user" do
    sign_in @user

    assert_api_response :get, 200 do
      assert_kind_of Array, parsed_body
      assert_equal "TestFeature", parsed_body.first["name"]
    end
  end

  test "GET /user-features with valid OAuth token" do
    token = create(:oauth_access_token, resource_owner_id: @user.id, scopes: ["profile:write"])

    assert_api_response :get, 200, headers: {"Authorization" => "Bearer #{token.token}"}
  end

  test "GET /user-features returns 401 with wrong-scope OAuth token" do
    token = create(:oauth_access_token, resource_owner_id: @user.id, scopes: ["public"])

    assert_api_response :get, 401, headers: {"Authorization" => "Bearer #{token.token}"}
  end

  test "GET /user-features returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /user-features excludes globally enabled features" do
    Flipper.enable("TestFeature")
    sign_in @user

    assert_api_response :get, 200 do
      assert_kind_of Array, parsed_body
      assert_empty parsed_body
    end
  end

  test "GET /user-features marks the viewer's own features as user-scoped" do
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal "user", parsed_body.first["scope"]
    end
  end

  test "GET /user-features lists a fleet-scoped feature the user may preview" do
    Flipper.add("FleetWideFeature")
    FeatureSetting.create!(feature_name: "FleetWideFeature", self_service_user: true, self_service_fleet: true)
    create(:fleet, members: [@user])
    sign_in @user

    assert_api_response :get, 200 do
      fleet_feature = parsed_body.find { |feature| feature["name"] == "FleetWideFeature" }

      assert_not_nil fleet_feature
      assert_equal "fleet", fleet_feature["scope"],
        "the scope is what tells the page this switch only covers the viewer"
      assert_not fleet_feature["enabled"]
      assert_not fleet_feature["enabledForSelf"]
    end
  end

  test "GET /user-features reports a fleet-scoped feature the user previews as enabled" do
    Flipper.add("FleetWideFeature")
    FeatureSetting.create!(feature_name: "FleetWideFeature", self_service_user: true, self_service_fleet: true)
    Flipper.enable_actor("FleetWideFeature", @user)
    sign_in @user

    assert_api_response :get, 200 do
      fleet_feature = parsed_body.find { |feature| feature["name"] == "FleetWideFeature" }

      assert fleet_feature["enabled"]
      assert fleet_feature["enabledForSelf"], "the switch stays theirs to flip back"
    end
  end

  test "GET /user-features reports a feature the fleet enabled as enabled" do
    Flipper.add("FleetWideFeature")
    FeatureSetting.create!(feature_name: "FleetWideFeature", self_service_user: true, self_service_fleet: true)
    fleet = create(:fleet, members: [@user])
    Flipper.enable_actor("FleetWideFeature", fleet)
    sign_in @user

    assert_api_response :get, 200 do
      fleet_feature = parsed_body.find { |feature| feature["name"] == "FleetWideFeature" }

      assert fleet_feature["enabled"],
        "the member has the feature, so the list must not ask them to turn it on"
      assert_not fleet_feature["enabledForSelf"],
        "and the page needs to know it came from the fleet, to disable the switch"
      assert_equal [{"name" => fleet.name, "slug" => fleet.slug}], fleet_feature["fleets"],
        "naming the fleet tells the member where the feature came from"
    end
  end

  test "GET /user-features names every fleet of the user's that enabled the feature" do
    Flipper.add("FleetWideFeature")
    FeatureSetting.create!(feature_name: "FleetWideFeature", self_service_user: true, self_service_fleet: true)
    granting = create(:fleet, members: [@user])
    other_granting = create(:fleet, members: [@user])
    create(:fleet, members: [@user])
    Flipper.enable_actor("FleetWideFeature", granting)
    Flipper.enable_actor("FleetWideFeature", other_granting)
    sign_in @user

    assert_api_response :get, 200 do
      slugs = parsed_body.find { |feature| feature["name"] == "FleetWideFeature" }["fleets"]
        .map { |fleet| fleet["slug"] }

      assert_equal [granting.slug, other_granting.slug].sort, slugs.sort,
        "the fleet that has it switched off is not responsible for anything"
    end
  end

  test "GET /user-features names no fleet for a feature the user enabled themselves" do
    Flipper.add("FleetWideFeature")
    FeatureSetting.create!(feature_name: "FleetWideFeature", self_service_user: true, self_service_fleet: true)
    create(:fleet, members: [@user])
    Flipper.enable_actor("FleetWideFeature", @user)
    sign_in @user

    assert_api_response :get, 200 do
      assert_empty parsed_body.find { |feature| feature["name"] == "FleetWideFeature" }["fleets"],
        "their own preview is not their fleet's doing, and stays theirs to switch off"
    end
  end

  test "GET /user-features ignores a fleet the user has only been invited to" do
    Flipper.add("FleetWideFeature")
    FeatureSetting.create!(feature_name: "FleetWideFeature", self_service_user: true, self_service_fleet: true)
    fleet = create(:fleet)
    create(:fleet_membership, :invited, fleet:, user: @user)
    Flipper.enable_actor("FleetWideFeature", fleet)
    sign_in @user

    assert_api_response :get, 200 do
      assert_not parsed_body.find { |feature| feature["name"] == "FleetWideFeature" }["enabled"],
        "a pending invitation is not membership"
    end
  end

  test "GET /user-features does not count a fleet gate on a user-scoped feature" do
    fleet = create(:fleet, members: [@user])
    Flipper.enable_actor("TestFeature", fleet)
    sign_in @user

    assert_api_response :get, 200 do
      assert_not parsed_body.find { |feature| feature["name"] == "TestFeature" }["enabled"],
        "nothing reads a user-scoped flag against a fleet, so such a gate grants nothing"
    end
  end

  test "GET /user-features lists a fleet-scoped feature for a user in no fleet" do
    Flipper.add("FleetWideFeature")
    FeatureSetting.create!(feature_name: "FleetWideFeature", self_service_user: true, self_service_fleet: true)
    sign_in @user

    assert_api_response :get, 200 do
      assert_includes parsed_body.map { |feature| feature["name"] }, "FleetWideFeature",
        "the toggle covers the viewer, so it does not depend on which fleets they are in"
    end
  end
end
