# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::GameMissionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/missions" do
    get("Missions list") do
      operationId "gameMissions"
      tags "Game Missions"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: GameMission.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: ::Admin::V1::Schemas::Queries::GameMissionQuery,
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, schema: {type: :string}, required: false

      response(200, "successful") do
        schema ::Admin::V1::Schemas::GameMissions
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/missions/{id}" do
    parameter name: "id", in: :path, description: "Mission id", schema: {type: :string, format: :uuid}, required: true

    get("Mission Detail") do
      operationId "gameMission"
      tags "Game Missions"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::GameMission
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
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

  test "GET /missions lists missions" do
    create_list(:game_mission, 2)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 2, parsed_body["items"].count
    end
  end

  test "GET /missions is refused without the privilege" do
    sign_in create(:admin_user, resource_access: [:blueprints])

    assert_api_response :get, 403
  end

  test "GET /missions is refused signed out" do
    assert_api_response :get, 401
  end

  test "GET /missions filters by nameCont" do
    create(:game_mission, name: "Simple Hit")
    create(:game_mission, name: "Wanna be a Headhunter?")
    sign_in @user

    assert_api_response :get, 200, params: {q: {"nameCont" => "Headhunter"}} do
      assert_equal ["Wanna be a Headhunter?"], parsed_body["items"].pluck("name")
    end
  end

  # A developer's note rather than a name, and searchable for exactly that
  # reason: it is how a row is found again in the export when its title is a
  # run-time template or absent.
  test "GET /missions finds a row by the debug name the export gave it" do
    create(:game_mission, debug_name: "TarPits_Stanton1_Dupree_Sabotage")
    create(:game_mission, debug_name: "Foxwell_ShipAmbush_VeryEasy")
    sign_in @user

    assert_api_response :get, 200, params: {q: {"debugNameCont" => "TarPits"}} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  # The public catalogue leaves the 74 unnamed contracts out entirely. Here
  # they are a filter, because "what did this load bring in that nobody can
  # read" is a question only this section asks.
  test "GET /missions finds the contracts the game never named" do
    named = create(:game_mission, name: "Simple Hit")
    unnamed = create(:game_mission, name: nil)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"named" => false}} do
      assert_equal [unnamed.id], parsed_body["items"].pluck("id")
      assert parsed_body["items"].first["unnamed"]
    end

    assert_api_response :get, 200, params: {q: {"named" => true}} do
      assert_equal [named.id], parsed_body["items"].pluck("id")
    end
  end

  # Defaulted to the fallback join where the public list pins the current build:
  # "what did this load retire" is one of the questions this section answers.
  test "GET /missions shows a mission the current build dropped" do
    retired = create(:game_mission, :without_build, version: nil, name: "Gone")
    retired.builds.create!(environment: ScData::Source.environment, version: "0.0.1-live.1", name: "Gone")
    create(:game_mission)
    sign_in @user

    assert_api_response :get, 200 do
      row = parsed_body["items"].find { |item| item["id"] == retired.id }

      assert row["retired"]
      assert_not row.dig("build", "current")
    end
  end

  test "GET /missions/{id} returns the mission with its rewards" do
    mission = create(:game_mission, name: "Simple Hit")
    create(:game_mission_reward, build: mission.build, amount: 100)
    sign_in @user

    assert_api_response :get, 200, params: {id: mission.id} do
      assert_equal "Simple Hit", parsed_body["name"]
      assert_equal ["reputation"], parsed_body["rewards"].pluck("kind")
      assert parsed_body.dig("build", "current")
    end
  end

  test "GET /missions/{id} 404s for an id nothing carries" do
    sign_in @user

    assert_api_response :get, 404, params: {id: SecureRandom.uuid}
  end
end
