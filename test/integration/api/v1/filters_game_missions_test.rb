# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FiltersGameMissionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/missions/orgs" do
    get("Mission orgs filter") do
      operationId "filtersGameMissionsOrgs"
      tags "Filters"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::FilterOptionsList
      end
    end
  end

  api_path "/filters/missions/standings" do
    get("Mission standings filter") do
      operationId "filtersGameMissionsStandings"
      tags "Filters"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::FilterOptionsList
      end
    end
  end

  api_path "/filters/missions/reward-kinds" do
    get("Mission reward kinds filter") do
      operationId "filtersGameMissionsRewardKinds"
      tags "Filters"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::FilterOptionsList
      end
    end
  end

  setup do
    create(:game_mission, org_name: "Foxwell Enforcement", org_key: "foxwell", min_standing: "Neutral")
    create(:game_mission, org_name: "Headhunters", org_key: "headhunters", min_standing: "Jr. Contractor")
  end

  test "GET /filters/missions/orgs lists the orgs that offer work" do
    assert_api_response :get, 200, api_path: "/filters/missions/orgs" do
      assert_equal ["Foxwell Enforcement", "Headhunters"], parsed_body.pluck("label")
      assert_equal %w[foxwell headhunters], parsed_body.pluck("value")
    end
  end

  # 25 of the 38 orgs the export declares a reputation record for offer work.
  # A select built from the reputation tree would offer thirteen options that
  # can only ever come back empty.
  test "GET /filters/missions/orgs leaves out an org that offers nothing" do
    create(:game_mission, :unattributed)

    assert_api_response :get, 200, api_path: "/filters/missions/orgs" do
      assert_equal 2, parsed_body.count
    end
  end

  # The band belongs to a build, so one only an older build offered work in is
  # not a band the current catalogue can be filtered by.
  test "GET /filters/missions/standings ignores a band only another build uses" do
    old = create(:game_mission, :without_build, version: nil)
    old.builds.create!(
      environment: ScData::Source.environment, version: "0.0.1-live.1", min_standing: "Retired Rank"
    )

    assert_api_response :get, 200, api_path: "/filters/missions/standings" do
      assert_equal ["Jr. Contractor", "Neutral"], parsed_body.pluck("label")
    end
  end

  # From the constant rather than from what is loaded: a kind nothing currently
  # pays is still a question worth being able to ask.
  #
  # One more than a reward row can be. A recipe is handed out through a reward
  # pool rather than as a contract result, so there is no row for it -- and a
  # reader filtering "what do I get" should not have to know that.
  test "GET /filters/missions/reward-kinds offers every kind a mission can pay" do
    assert_api_response :get, 200, api_path: "/filters/missions/reward-kinds" do
      assert_equal GameMissionBuild::REWARD_KINDS, parsed_body.pluck("value")
      assert_includes parsed_body.pluck("value"), "blueprint"
    end
  end
end
