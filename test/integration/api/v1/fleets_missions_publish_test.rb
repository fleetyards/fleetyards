# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsMissionsPublishTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/missions/{slug}/publish" do
    put("Publish mission") do
      operationId "publishMission"
      tags "Missions"
      produces "application/json"

      parameter name: :fleetSlug, in: :path, schema: {type: :string}, required: true
      parameter name: :slug, in: :path, schema: {type: :string}, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      # `publish` renders :show, which carries the teams -- so the documented
      # response is the extended one, the same as the show endpoint's.
      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Missions::MissionExtended
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_mission_builder")
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
    @mission = create(:mission, :draft, fleet: @fleet, created_by: @admin)
  end

  test "PUT /fleets/:slug/missions/:slug/publish offers the mission to the fleet" do
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @mission.slug} do
      assert_equal "published", parsed_body["status"]
    end

    assert @mission.reload.published?
  end

  # Publishing again is the same answer rather than an error: a second click on
  # a slow connection must not read as a failure.
  test "PUT /fleets/:slug/missions/:slug/publish is idempotent" do
    published = create(:mission, fleet: @fleet, created_by: @admin)
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, slug: published.slug} do
      assert_equal "published", parsed_body["status"]
    end
  end

  # 404 rather than 403: a draft is not on this member's list and is not
  # readable by slug either, so the answer must not confirm that it exists.
  test "PUT /fleets/:slug/missions/:slug/publish hides another author's draft" do
    sign_in @member

    assert_api_response :put, 404,
      path_params: {fleetSlug: @fleet.slug, slug: @mission.slug}

    assert @mission.reload.draft?
  end

  test "PUT /fleets/:slug/missions/:slug/publish returns 403 for a member who may read it" do
    published = create(:mission, fleet: @fleet, created_by: @admin)
    sign_in @member

    assert_api_response :put, 403,
      path_params: {fleetSlug: @fleet.slug, slug: published.slug}
  end

  test "PUT /fleets/:slug/missions/:slug/publish returns 401 when not signed in" do
    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, slug: @mission.slug}
  end
end
