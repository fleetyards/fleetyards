# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsSquadronRolesUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/squadron-roles/{id}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "Squadron role id"

    put("Rename Fleet Squadron Role") do
      operationId "updateFleetSquadronRole"
      tags "FleetSquadrons"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetSquadronRoleUpdateInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Squadrons::FleetSquadronRole
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden - renaming a rank needs fleet:squadrons:manage") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_squadrons")
    @admin = create(:user)
    @officer = create(:user)
    @fleet = create(:fleet, :with_squadrons, admins: [@admin], officers: [@officer])
    @leader = @fleet.fleet_squadron_roles.find_by!(key: "leader")
  end

  def path_params(id = @leader.id)
    {fleetSlug: @fleet.slug, id:}
  end

  test "PUT squadron role renames the rank" do
    sign_in @admin

    assert_api_response :put, 200, path_params: path_params, body: {name: "Wing Commander"} do
      assert_equal "Wing Commander", parsed_body["name"]
      assert_equal "leader", parsed_body["key"]
    end

    assert_equal "Wing Commander", @leader.reload.name
  end

  test "PUT squadron role refuses a blank name" do
    sign_in @admin

    assert_api_response :put, 400, path_params: path_params, body: {name: ""}
  end

  # Officers post people to squadrons; how the squadrons are organised is the
  # admins' call.
  test "PUT squadron role is forbidden for a fleet officer" do
    sign_in @officer

    assert_api_response :put, 403, path_params: path_params, body: {name: "Wing Commander"}
  end

  test "PUT squadron role returns 404 for another fleet's rank" do
    other = create(:fleet).fleet_squadron_roles.find_by!(key: "leader")
    sign_in @admin

    assert_api_response :put, 404, path_params: path_params(other.id), body: {name: "Wing Commander"}
  end

  test "PUT squadron role returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: path_params, body: {name: "Wing Commander"}
  end
end
