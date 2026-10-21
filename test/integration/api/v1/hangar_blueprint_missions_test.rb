# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarBlueprintMissionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  PATH = "/hangar/blueprint-missions"

  api_path PATH do
    get("Missions that hand out a wanted blueprint") do
      operationId "hangarBlueprintMissions"
      tags "Hangar"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: GameMission.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::GameMissionQuery,
        style: :deepObject,
        explode: true,
        required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Hangar::HangarBlueprintMissions
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:user)

    @wanted = create(:blueprint, name: "Bulldog Repeater")
    @owned = create(:blueprint, name: "Omnisky VI Cannon")
    create(:user_blueprint, :wanted, user: @user, blueprint: @wanted)
    create(:user_blueprint, user: @user, blueprint: @owned)

    @hunt = mission_dropping(@wanted, name: "Simple Hit")
    @other = mission_dropping(@owned, name: "Ambush An Amateur")
    create(:game_mission, name: "Deliver Cargo")
  end

  def mission_dropping(blueprint, name:)
    pool_ref = Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "pool-#{name}")
    create(:blueprint_source, build: blueprint.build, pool_sc_ref: pool_ref)

    create(:game_mission, name:).tap do |mission|
      mission.update!(blueprint_pool_refs: [pool_ref])
      mission.build.update!(blueprint_pool_refs: [pool_ref])
    end
  end

  test "GET lists the missions that hand out a wanted blueprint, and which" do
    sign_in @user

    assert_api_response :get, 200, api_path: PATH do
      items = parsed_body["items"]

      assert_equal [@hunt.id], items.pluck("id")
      assert_equal "Simple Hit", items.first["mission"]["name"]
      assert_equal ["Bulldog Repeater"], items.first["wantedBlueprints"].pluck("name")
    end
  end

  # Generated from the wishlist alone: taking a blueprint off it takes its
  # missions with it.
  test "GET is empty without a wishlist" do
    UserBlueprint.wanted.where(user: @user).destroy_all
    sign_in @user

    assert_api_response :get, 200, api_path: PATH do
      assert_empty parsed_body["items"]
    end
  end

  # One mission whose pools hold two wanted blueprints is one row naming both.
  test "GET names every wanted blueprint a mission hands out" do
    second = create(:blueprint, name: "Attrition-3 Repeater")
    create(:user_blueprint, :wanted, user: @user, blueprint: second)
    create(:blueprint_source, build: second.build, pool_sc_ref: @hunt.blueprint_pool_refs.first)

    sign_in @user

    assert_api_response :get, 200, api_path: PATH do
      assert_equal [@hunt.id], parsed_body["items"].pluck("id")
      assert_equal ["Attrition-3 Repeater", "Bulldog Repeater"],
        parsed_body["items"].first["wantedBlueprints"].pluck("name")
    end
  end

  # Somebody else's wishlist is not the reader's.
  test "GET reads the reader's wishlist only" do
    sign_in create(:user)

    assert_api_response :get, 200, api_path: PATH do
      assert_empty parsed_body["items"]
    end
  end

  test "GET takes the mission catalogue's filters" do
    mission_dropping(@wanted, name: "Recover Stolen Goods")
    sign_in @user

    assert_api_response :get, 200, api_path: PATH, params: {q: {"nameCont" => "Recover"}} do
      assert_equal ["Recover Stolen Goods"], parsed_body["items"].pluck("mission").pluck("name")
    end
  end

  # Asked for retired missions too, the wishlist side reads the same builds: a
  # recipe and a mission the current build both dropped still meet.
  test "GET with currentVersion false matches on the last builds of both" do
    @wanted.build.update!(version: "4.0.0")
    @hunt.build.update!(version: "4.0.0")
    sign_in @user

    assert_api_response :get, 200, api_path: PATH do
      assert_empty parsed_body["items"]
    end

    assert_api_response :get, 200, api_path: PATH, params: {q: {"currentVersion" => false}} do
      assert_equal [@hunt.id], parsed_body["items"].pluck("id")
      assert_equal ["Bulldog Repeater"], parsed_body["items"].first["wantedBlueprints"].pluck("name")
    end
  end

  test "GET without a session is refused" do
    assert_api_response :get, 401, api_path: PATH
  end
end
