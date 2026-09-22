# frozen_string_literal: true

require "openapi_helper"

class Api::V1::GameMissionsShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/missions/{slug}" do
    get("Mission detail") do
      operationId "gameMission"
      tags "Game Missions"
      produces "application/json"

      parameter name: "slug", in: :path, schema: {type: :string}, required: true

      response(200, "successful") do
        schema ::Shared::V1::Schemas::GameMission
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @mission = create(
      :game_mission,
      name: "Yellow Level Contract: Ambush An Amateur",
      sc_key: "foxwellenforcement_ambush_veryeasy",
      description: "Somebody at ~mission(Location|Address) needs teaching a lesson.",
      generator_key: "foxwellenforcement_ambush",
      debug_name: "Foxwell_ShipAmbush_VeryEasy",
      reward_kinds: %w[reputation currency]
    )
    create(:game_mission_reward, build: @mission.build, amount: 100, position: 0)
    create(:game_mission_reward, :currency, build: @mission.build, position: 1)
  end

  test "GET /missions/{slug} returns the mission" do
    assert_api_response :get, 200, params: {slug: @mission.slug} do
      assert_equal "Yellow Level Contract: Ambush An Amateur", parsed_body["name"]
      assert_equal "foxwellenforcement-ambush-veryeasy", parsed_body["slug"]
      assert_equal "career", parsed_body["kind"]
      assert parsed_body["released"]
    end
  end

  test "GET /missions/{slug} names the org and the standing band it is offered in" do
    assert_api_response :get, 200, params: {slug: @mission.slug} do
      assert_equal "Foxwell Enforcement", parsed_body.dig("org", "name")
      assert_equal "lawful", parsed_body.dig("org", "alignment")
      assert_equal "Neutral", parsed_body["minStanding"]
      assert_equal "Elite Contractor", parsed_body["maxStanding"]
    end
  end

  test "GET /missions/{slug} carries the difficulty the game's designers rated it" do
    assert_api_response :get, 200, params: {slug: @mission.slug} do
      assert_equal "general", parsed_body.dig("difficulty", "profile")
      assert_equal 3, parsed_body.dig("difficulty", "mechanicalSkill")
      assert_equal 2, parsed_body.dig("difficulty", "riskOfLoss")
    end
  end

  # What the export is willing to state, in the order the results declare it.
  test "GET /missions/{slug} carries every reward the build states" do
    assert_api_response :get, 200, params: {slug: @mission.slug} do
      rewards = parsed_body["rewards"]

      assert_equal %w[reputation currency], rewards.pluck("kind")
      assert_equal 100, rewards.first["amount"]
      assert_equal "Foxwell Enforcement", rewards.first["orgName"]
      assert_equal 40_000, rewards.last["amount"]
      assert_equal "UEC", rewards.last["currency"]
    end
  end

  # An award states a ref and nothing else, so without the name the page shows
  # a GUID. 405 of the 410 resolve, and the two commonest are physical currency.
  test "GET /missions/{slug} names what an item award hands over" do
    create(:game_mission_reward, :item, build: @mission.build, entity_name: "MG Scrip", position: 2)

    assert_api_response :get, 200, params: {slug: @mission.slug} do
      item = parsed_body["rewards"].find { |reward| reward["kind"] == "item" }

      assert_equal "MG Scrip", item["entityName"]
    end
  end

  # The run-time spans reach the payload as the export writes them: stripping
  # one here would break the sentence around it, and what to do with it is the
  # renderer's decision.
  test "GET /missions/{slug} passes the description on unchanged" do
    assert_api_response :get, 200, params: {slug: @mission.slug} do
      assert_includes parsed_body["description"], "~mission(Location|Address)"
    end
  end

  # 786 of the 2,536 contracts hand out a recipe, and this is the only place
  # that link can be followed: `blueprint_sources` carries the mission's *name*
  # rather than a reference to it, and 45 titles are shared by two orgs.
  test "GET /missions/{slug} names the recipes the pools it hands out contain" do
    pool_ref = Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "pool-link")
    @mission.update!(blueprint_pool_refs: [pool_ref])
    @mission.build.update!(blueprint_pool_refs: [pool_ref])
    blueprint = create(:blueprint, name: "Bulldog Repeater")
    create(:blueprint_source, build: blueprint.build, pool_sc_ref: pool_ref)

    assert_api_response :get, 200, params: {slug: @mission.slug} do
      assert_equal ["Bulldog Repeater"], parsed_body["blueprints"].pluck("name")
      assert_equal [blueprint.slug], parsed_body["blueprints"].pluck("slug")
    end
  end

  test "GET /missions/{slug} hands out nothing where the contract names no pool" do
    assert_api_response :get, 200, params: {slug: @mission.slug} do
      assert_empty parsed_body["blueprints"]
    end
  end

  # 2,352 of the 2,360 contracts that pay leave the figure to the game. Saying
  # that outright is the difference between "we do not know" and "it pays
  # nothing", and the page has to be able to tell them apart.
  test "GET /missions/{slug} says a payout is the game's to work out" do
    create(:game_mission_reward, build: @mission.build, kind: "currency", amount: nil, org_name: nil, org_key: nil, position: 3)

    assert_api_response :get, 200, params: {slug: @mission.slug} do
      computed = parsed_body["rewards"].select { |reward| reward["kind"] == "currency" }

      assert_includes computed.pluck("calculated"), true
      assert_includes computed.pluck("calculated"), false
    end
  end

  test "GET /missions/{slug} 404s for a slug nothing carries" do
    assert_api_response :get, 404, params: {slug: "nope-nothing-here"}
  end

  # A contract the export dropped still resolves: a link to it was valid once,
  # and the page says so rather than 404ing.
  test "GET /missions/{slug} answers for a retired mission" do
    retired = create(:game_mission, :without_build, version: nil, sc_key: "generator_gone")
    retired.builds.create!(
      environment: ScData::Source.environment, version: "0.0.1-live.1", name: "Gone"
    )

    assert_api_response :get, 200, params: {slug: retired.slug} do
      assert parsed_body["retired"]
      assert_equal "Gone", parsed_body["name"]
    end
  end
end
