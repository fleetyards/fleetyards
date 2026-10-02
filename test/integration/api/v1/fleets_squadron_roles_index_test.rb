# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsSquadronRolesIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/squadron-roles" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Fleet Squadron Role List") do
      operationId "fleetSquadronRoles"
      tags "FleetSquadrons"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Squadrons::FleetSquadronRolesList
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden - the role reads no squadrons") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_squadrons")
    @member = create(:user)
    @fleet = create(:fleet, :with_squadrons, members: [@member])
  end

  test "GET squadron roles lists the fleet's four ranks in order" do
    sign_in @member

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal %w[leader co_leader officer member], parsed_body.map { |rank| rank["key"] }
      assert_equal "Squadron Leader", parsed_body.first["name"]
    end
  end

  test "GET squadron roles returns 403 for a role that reads no squadrons" do
    reader = create(:user)
    role = create(:fleet_role, fleet: @fleet, name: "No Squadrons", resource_access: ["fleet:memberships:read"])
    create(:fleet_membership, :accepted, fleet: @fleet, user: reader, fleet_role: role)
    sign_in reader

    assert_api_response :get, 403, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET squadron roles returns 404 for an unknown fleet" do
    sign_in @member

    assert_api_response :get, 404, path_params: {fleetSlug: "unknown-fleet"}
  end

  test "GET squadron roles returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end
end
