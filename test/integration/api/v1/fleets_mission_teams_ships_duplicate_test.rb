# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsMissionTeamsShipsDuplicateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/missions/{missionSlug}/teams/{missionTeamId}/ships/{id}/duplicate" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "missionSlug", in: :path, schema: {type: :string}
    parameter name: "missionTeamId", in: :path, schema: {type: :string}
    parameter name: "id", in: :path, schema: {type: :string}

    post("Duplicate Mission Ship") do
      operationId "duplicateMissionShip"
      tags "Missions"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/MissionShip"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Flipper.enable("fleet_mission_builder")
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
    @mission = create(:mission, fleet: @fleet, created_by: @admin)
    @team = create(:mission_team, mission: @mission)
    @ship = create(:mission_ship, mission_team: @team, title: "Escort",
      description: "Runs point", classification: "combat", min_crew: 2)
  end

  def path_params
    {
      fleetSlug: @fleet.slug,
      missionSlug: @mission.slug,
      missionTeamId: @team.id,
      id: @ship.id
    }
  end

  test "POST .../ships/:id/duplicate copies the ship to the end of the team" do
    sign_in @admin

    assert_api_response :post, 201, path_params: path_params do
      assert_equal 2, @team.mission_ships.count
      assert_equal "Escort", parsed_body["title"]
      assert_equal "Runs point", parsed_body["description"]
      assert_equal 2, parsed_body["filters"]["minCrew"]
      assert_not_equal @ship.id, parsed_body["id"]
      assert_equal @team.mission_ships.maximum(:position), parsed_body["position"]
    end
  end

  test "POST .../ships/:id/duplicate copies the slots as they stand" do
    @ship.mission_slots.create!(title: "Pilot", position: 0)
    @ship.mission_slots.create!(title: "Renamed gunner", description: "Top turret", position: 1)
    sign_in @admin

    assert_api_response :post, 201, path_params: path_params do
      copy = @team.mission_ships.order(:position).last

      assert_equal ["Pilot", "Renamed gunner"], copy.mission_slots.order(:position).pluck(:title)
      assert_equal "Top turret", copy.mission_slots.order(:position).last.description
    end
  end

  test "POST .../ships/:id/duplicate returns 401 without a session" do
    assert_api_response :post, 401, path_params: path_params
  end
end
