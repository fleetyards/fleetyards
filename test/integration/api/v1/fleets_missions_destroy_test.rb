# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsMissionsDestroyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/missions/{slug}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}

    delete("Archive Mission") do
      operationId "destroyFleetMission"
      tags "Missions"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful - archived") do
        schema "$ref": "#/components/schemas/MissionExtended"
      end

      response(204, "successful - permanent delete on already-archived mission") do
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Flipper.enable("mission_builder")
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
    @mission = create(:mission, fleet: @fleet, created_by: @admin)
  end

  test "DELETE /fleets/:slug/missions/:slug archives an active mission" do
    sign_in @admin

    assert_api_response :delete, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @mission.slug} do
      assert_equal true, parsed_body["archived"]
    end
    assert @mission.reload.archived?
  end

  test "DELETE /fleets/:slug/missions/:slug permanently deletes an already-archived mission" do
    archived = create(:mission, :archived, fleet: @fleet, created_by: @admin)
    sign_in @admin

    assert_api_response :delete, 204,
      path_params: {fleetSlug: @fleet.slug, slug: archived.slug}

    assert_raises(ActiveRecord::RecordNotFound) { archived.reload }
  end

  test "DELETE /fleets/:slug/missions/:slug with OAuth bearer token" do
    assert_api_response :delete, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @mission.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"])
  end

  test "DELETE /fleets/:slug/missions/:slug returns 401 for OAuth token with wrong scope" do
    assert_api_response :delete, 401,
      path_params: {fleetSlug: @fleet.slug, slug: @mission.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"])
  end

  test "DELETE /fleets/:slug/missions/:slug returns 401 when not signed in" do
    assert_api_response :delete, 401,
      path_params: {fleetSlug: @fleet.slug, slug: @mission.slug}
  end
end
