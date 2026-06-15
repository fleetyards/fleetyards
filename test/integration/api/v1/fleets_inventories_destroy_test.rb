# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsInventoriesDestroyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/inventories/{slug}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Inventory slug"

    delete("Delete Fleet Inventory") do
      operationId "destroyFleetInventory"
      tags "FleetInventories"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(204, "successful")

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden - member cannot delete") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Flipper.enable("fleet_logistics")
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
    @inventory = create(:fleet_inventory, fleet: @fleet)
  end

  test "DELETE /fleets/:slug/inventories/:slug deletes the inventory" do
    sign_in @admin

    assert_api_response :delete, 204, path_params: {fleetSlug: @fleet.slug, slug: @inventory.slug}

    assert_nil FleetInventory.find_by(id: @inventory.id)
  end

  test "DELETE /fleets/:slug/inventories/:slug returns 403 for non-admin member" do
    sign_in @member

    assert_api_response :delete, 403, path_params: {fleetSlug: @fleet.slug, slug: @inventory.slug}
  end

  test "DELETE /fleets/:slug/inventories/:slug returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: {fleetSlug: @fleet.slug, slug: @inventory.slug}
  end

  test "DELETE /fleets/:slug/inventories/:slug with OAuth bearer token" do
    assert_api_response :delete, 204,
      path_params: {fleetSlug: @fleet.slug, slug: @inventory.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"])
  end
end
