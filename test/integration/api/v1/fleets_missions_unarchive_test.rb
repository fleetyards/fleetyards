# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsMissionsUnarchiveTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/missions/{slug}/unarchive" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}

    put("Unarchive Mission") do
      operationId "unarchiveFleetMission"
      tags "Missions"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Missions::MissionExtended
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_mission_builder")
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
    @mission = create(:mission, fleet: @fleet, created_by: @admin,
      archived_at: 1.day.ago)
  end

  test "PUT /fleets/:slug/missions/:slug/unarchive restores the mission" do
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @mission.slug} do
      assert_nil @mission.reload.archived_at
    end
  end

  test "PUT /fleets/:slug/missions/:slug/unarchive returns 401 without a session" do
    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, slug: @mission.slug}
  end
end
