# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsRolesUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/roles/{id}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "Fleet role id"

    put("Rename Fleet Role") do
      operationId "updateFleetRole"
      tags "FleetRoles"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetRoleUpdateInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::FleetRoleExtended
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden - renaming a role needs fleet:roles:update") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
    @member_role = @fleet.fleet_roles.find_by!(slug: "member")
  end

  def path_params(id = @member_role.id)
    {fleetSlug: @fleet.slug, id:}
  end

  test "PUT /fleets/:slug/roles/:id renames the role and keeps its slug" do
    sign_in @admin

    assert_api_response :put, 200, path_params: path_params, body: {name: "Recruit"} do
      assert_equal "Recruit", parsed_body["name"]
      assert_equal "member", parsed_body["slug"]
      assert parsed_body["defaultRole"]
    end
  end

  test "PUT /fleets/:slug/roles/:id refuses a name another role has" do
    sign_in @admin

    assert_api_response :put, 400, path_params: path_params, body: {name: "officer"}
  end

  test "PUT /fleets/:slug/roles/:id is forbidden for a plain member" do
    sign_in @member

    assert_api_response :put, 403, path_params: path_params, body: {name: "Recruit"}
  end

  test "PUT /fleets/:slug/roles/:id returns 404 for another fleet's role" do
    other = create(:fleet).fleet_roles.find_by!(slug: "member")
    sign_in @admin

    assert_api_response :put, 404, path_params: path_params(other.id), body: {name: "Recruit"}
  end

  test "PUT /fleets/:slug/roles/:id returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: path_params, body: {name: "Recruit"}
  end
end
