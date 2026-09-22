# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::GameMissionFiltersTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/missions/org_filters" do
    get("Mission orgs") do
      operationId "gameMissionOrgs"
      tags "Game Missions"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::FilterOptionsList
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/missions/standing_filters" do
    get("Mission standings") do
      operationId "gameMissionStandings"
      tags "Game Missions"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::FilterOptionsList
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/missions/reward_kind_filters" do
    get("Mission reward kinds") do
      operationId "gameMissionRewardKinds"
      tags "Game Missions"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::FilterOptionsList
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:admin_user, resource_access: [:missions])
  end

  test "GET /missions/org_filters lists the orgs that offer work" do
    create(:game_mission, org_name: "Foxwell Enforcement", org_key: "foxwell")
    create(:game_mission, :unattributed)
    sign_in @user

    assert_api_response :get, 200, api_path: "/missions/org_filters" do
      assert_equal ["Foxwell Enforcement"], parsed_body.pluck("label")
    end
  end

  # The admin list defaults to the fallback join, so an option list pinned to
  # the build we are on would omit an org a visible row names. An option that
  # matches nothing costs a click; a missing one cannot be asked for at all.
  test "GET /missions/org_filters offers an org only an older build names" do
    mission = create(:game_mission, :without_build, version: nil)
    mission.builds.create!(
      environment: ScData::Source.environment, version: "0.0.1-live.1",
      name: "Gone", org_name: "Retired Org", org_key: "retired"
    )
    create(:game_mission)
    sign_in @user

    assert_api_response :get, 200, api_path: "/missions/org_filters" do
      assert_includes parsed_body.pluck("label"), "Retired Org"
    end
  end

  test "GET /missions/standing_filters lists the bands work is offered in" do
    create(:game_mission, min_standing: "Neutral")
    sign_in @user

    assert_api_response :get, 200, api_path: "/missions/standing_filters" do
      assert_equal ["Neutral"], parsed_body.pluck("label")
    end
  end

  # One more than a reward row can be: a recipe comes from a reward pool rather
  # than from a contract result.
  test "GET /missions/reward_kind_filters offers every kind a mission can pay" do
    sign_in @user

    assert_api_response :get, 200, api_path: "/missions/reward_kind_filters" do
      assert_equal GameMissionBuild::REWARD_KINDS, parsed_body.pluck("value")
    end
  end

  test "GET /missions/org_filters is refused without the privilege" do
    sign_in create(:admin_user, resource_access: [:blueprints])

    assert_api_response :get, 403, api_path: "/missions/org_filters"
  end

  test "GET /missions/org_filters is refused signed out" do
    assert_api_response :get, 401, api_path: "/missions/org_filters"
  end
end
