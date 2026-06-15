# frozen_string_literal: true

require "openapi_helper"

class Api::V1::MissionSlotsDestroyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/mission-slots/{id}" do
    parameter name: "id", in: :path, schema: {type: :string}

    delete("Destroy Mission Slot") do
      operationId "destroyMissionSlot"
      tags "Missions"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(204, "successful") do
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
    @team = create(:mission_team, mission: @mission)
    @slot = create(:mission_slot, slottable: @team)
  end

  test "DELETE /mission-slots/:id destroys the slot" do
    sign_in @admin

    assert_api_response :delete, 204, path_params: {id: @slot.id}

    assert_raises(ActiveRecord::RecordNotFound) { @slot.reload }
  end

  test "DELETE /mission-slots/:id with OAuth bearer token" do
    assert_api_response :delete, 204,
      path_params: {id: @slot.id},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"])
  end

  test "DELETE /mission-slots/:id returns 401 for OAuth token with wrong scope" do
    assert_api_response :delete, 401,
      path_params: {id: @slot.id},
      headers: oauth_headers_for(@admin, scopes: ["public"])
  end

  test "DELETE /mission-slots/:id returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: {id: @slot.id}
  end
end
