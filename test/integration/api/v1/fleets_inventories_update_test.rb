# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsInventoriesUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/inventories/{slug}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Inventory slug"

    put("Update Fleet Inventory") do
      operationId "updateFleetInventory"
      tags "FleetInventories"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetInventoryUpdateInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Logistics::FleetInventory
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden - member cannot update") do
        schema ::Shared::V1::Schemas::StandardError
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

  test "PUT /fleets/:slug/inventories/:slug updates the inventory" do
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @inventory.slug},
      body: {name: "Renamed"} do
      assert_equal "Renamed", parsed_body["name"]
    end
  end

  # The picture somebody picked, held next to the attachment rather than as one:
  # the art it names ships with the app, not with the record.
  test "PUT /fleets/:slug/inventories/:slug records the picture that was picked" do
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @inventory.slug},
      body: {imagePreset: "bg-hangar"} do
      assert_equal "bg-hangar", parsed_body["imagePreset"]
    end

    assert_equal "bg-hangar", @inventory.reload.image_preset
  end

  test "PUT /fleets/:slug/inventories/:slug returns 403 for non-admin member" do
    sign_in @member

    assert_api_response :put, 403,
      path_params: {fleetSlug: @fleet.slug, slug: @inventory.slug},
      body: {name: "Renamed"}
  end

  test "PUT /fleets/:slug/inventories/:slug returns 401 when not signed in" do
    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, slug: @inventory.slug},
      body: {name: "Renamed"}
  end

  test "PUT /fleets/:slug/inventories/:slug with OAuth bearer token" do
    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @inventory.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {name: "OAuth Renamed"}
  end
end
