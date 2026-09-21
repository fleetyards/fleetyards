# frozen_string_literal: true

require "openapi_helper"

class Api::V1::GameMissionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/missions" do
    get("Missions list") do
      operationId "gameMissions"
      tags "Game Missions"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: GameMission.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::GameMissionQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::Shared::V1::Schemas::GameMissions
      end
    end
  end

  setup do
    @ambush = create(
      :game_mission,
      name: "Yellow Level Contract: Ambush An Amateur",
      sc_key: "foxwellenforcement_ambush_veryeasy",
      org_name: "Foxwell Enforcement",
      org_key: "factionreputation_lawful_foxwellenforcement",
      alignment: "lawful",
      min_standing: "Neutral",
      reward_kinds: %w[reputation]
    )
    @hit = create(
      :game_mission,
      name: "Simple Hit",
      sc_key: "headhunters_simple_hit",
      kind: "contract",
      org_name: "Headhunters",
      org_key: "factionreputation_unlawful_headhunters",
      alignment: "outlaw",
      org_lawful: false,
      min_standing: "Jr. Contractor",
      reward_kinds: %w[reputation item]
    )
  end

  test "GET /missions lists the catalogue" do
    assert_api_response :get, 200 do
      assert_equal 2, parsed_body["items"].count
    end
  end

  test "GET /missions filters by nameCont" do
    assert_api_response :get, 200, params: {q: {"nameCont" => "Ambush"}} do
      items = parsed_body["items"]

      assert_equal 1, items.count
      assert_equal "Yellow Level Contract: Ambush An Amateur", items.first["name"]
    end
  end

  test "GET /missions filters by the org that offers the work" do
    assert_api_response :get, 200, params: {q: {"fromOrg" => "Headhunters"}} do
      assert_equal [@hit.id], parsed_body["items"].pluck("id")
    end
  end

  test "GET /missions filters by which side of the law offers it" do
    assert_api_response :get, 200, params: {q: {"alignmentIn" => ["outlaw"]}} do
      assert_equal [@hit.id], parsed_body["items"].pluck("id")
    end
  end

  test "GET /missions filters by what the mission pays" do
    assert_api_response :get, 200, params: {q: {"rewarding" => "item"}} do
      assert_equal [@hit.id], parsed_body["items"].pluck("id")
    end
  end

  # Ransack skips a scope handed a false value, so a released filter reached
  # through it would answer "what is the build not offering" with everything.
  # This is the assertion that the controller applies it by hand.
  test "GET /missions answers releasedFalse with what the build is not offering" do
    withheld = create(:game_mission, :unreleased, name: "Work In Progress")

    assert_api_response :get, 200, params: {q: {"released" => false}} do
      assert_equal [withheld.id], parsed_body["items"].pluck("id")
    end
  end

  test "GET /missions answers releasedTrue with only what it is" do
    create(:game_mission, :unreleased)

    assert_api_response :get, 200, params: {q: {"released" => true}} do
      assert_equal [@ambush.id, @hit.id].sort, parsed_body["items"].pluck("id").sort
    end
  end

  # A recipe comes from a reward pool rather than from a contract result, so
  # there is no reward row for it -- but it is something the mission pays, and
  # this is the assertion that a reader can filter for it like any other.
  test "GET /missions filters by the missions that hand out a recipe" do
    dropping = create(:game_mission, name: "Wanna be a Headhunter?", reward_kinds: %w[reputation blueprint])

    assert_api_response :get, 200, params: {q: {"rewarding" => "blueprint"}} do
      assert_equal [dropping.id], parsed_body["items"].pluck("id")
    end
  end

  test "GET /missions sorts by org name" do
    assert_api_response :get, 200, params: {q: {"sorts" => ["orgName desc"]}} do
      assert_equal "Headhunters", parsed_body["items"].first.dig("org", "name")
    end
  end

  # The list is the cheap half of the pair: a description runs to 1,200
  # characters and 60 of them would be prose nothing renders.
  test "GET /missions leaves the description and the rewards to the detail page" do
    assert_api_response :get, 200, params: {q: {"sorts" => ["name asc"]}} do
      item = parsed_body["items"].find { |record| record["id"] == @ambush.id }

      assert_not item.key?("description")
      assert_not item.key?("rewards")
      assert_equal ["reputation"], item["rewardKinds"]
    end
  end

  # `?page[]=1` arrives as an Array and kaminari calls `to_i` on it, which is an
  # unhandled 500 rather than a page of missions.
  test "GET /missions survives a page parameter that is not a scalar" do
    assert_api_response :get, 200, params: {page: ["1"]} do
      assert_equal 2, parsed_body["items"].count
    end
  end

  test "GET /missions excludes a retired mission by default" do
    retired = create(:game_mission, :without_build, version: nil)

    assert_api_response :get, 200 do
      assert_not_includes parsed_body["items"].pluck("id"), retired.id
    end

    assert_api_response :get, 200, params: {q: {"currentVersion" => false}} do
      assert_includes parsed_body["items"].pluck("id"), retired.id
    end
  end
end
