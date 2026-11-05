# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FactionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/factions" do
    get("Factions") do
      operationId "factions"
      tags "Factions"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::FactionsList
      end
    end
  end

  api_path "/factions/{slug}" do
    get("Faction detail") do
      operationId "faction"
      tags "Factions"
      produces "application/json"

      parameter name: "slug", in: :path, schema: {type: :string}, required: true

      response(200, "successful") do
        schema ::V1::Schemas::FactionDetail
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @faction = create(:faction, sc_key: "factionreputation_lawful_redwindlinehaul", name: "Red Wind Linehaul")
    create(:faction_ladder, build: @faction.build, position: 0)
    create(:faction_ladder, build: @faction.build, key: "reputationscope_affinity", name: "Affinity",
      ranks: [{name: "Neutral", min_reputation: 0}], position: 1)

    mission = create(:game_mission, org_key: @faction.sc_key)
    create(:game_mission_reward, build: mission.build, amount: 250, outcome: "completed",
      org_key: @faction.sc_key, ladder_key: "reputationscope_hauling", ladder_name: "Hauling")
  end

  test "GET /factions lists current factions by name, with what each offers" do
    create(:faction, name: "Adagio Holdings")
    create(:faction, name: "Port Tressler Gone", version: nil, with_build: false)

    assert_api_response :get, 200 do
      assert_equal ["Adagio Holdings", "Red Wind Linehaul"], parsed_body.pluck("name")
      assert_equal [0, 1], parsed_body.pluck("missionCount")
    end
  end

  test "GET /factions/{slug} states its ladders in order, with what missions pay into them" do
    assert_api_response :get, 200, params: {slug: "redwindlinehaul"} do
      hauling, affinity = parsed_body["ladders"]

      assert_equal "Red Wind Linehaul", parsed_body["name"]
      assert_equal "Hauling", hauling["name"]
      assert_equal({"name" => "Rookie", "minReputation" => 50}, hauling["ranks"].last)
      assert_equal [1, 250, 250], hauling.values_at("missionCount", "minAward", "maxAward")
      assert_equal [0, nil, nil], affinity.values_at("missionCount", "minAward", "maxAward")
    end
  end

  test "GET /factions/{slug} answers 404 for a slug nothing carries" do
    assert_api_response :get, 404, params: {slug: "nobody"}
  end
end
