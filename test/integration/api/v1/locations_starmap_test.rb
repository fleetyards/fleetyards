# frozen_string_literal: true

require "openapi_helper"

class Api::V1::LocationsStarmapTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/locations/{slug}/starmap" do
    get("Location system starmap") do
      operationId "locationStarmap"
      tags "Locations"
      produces "application/json"

      parameter name: "slug", in: :path, schema: {type: :string}, required: true

      response(200, "successful") do
        schema ::V1::Schemas::LocationStarmap
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @system = create(:location, name: "Stanton System", sc_key: "StantonSolarSystem", kind: "system")
    @star = create(:location, name: "Stanton", sc_key: "StantonStar", kind: "star", parent: @system, system: @system,
      position: [0.0, 0.0, 0.0], radius: 696_000_000.0)
    @hurston = create(:location, name: "Hurston", sc_key: "Stanton1", kind: "planet", parent: @star, system: @system,
      position: [12_850_457_093.0, 0.0, 0.0], radius: 1_000_000.0)
    @lagrange = create(:location, name: "HUR-L1", sc_key: "Stanton1_L1", kind: "asteroid", parent: @hurston, system: @system,
      position: [11_565_411_383.0, 0.0, 0.0])
    @gateway = create(:location, name: "Pyro Gateway", sc_key: "RR_JP_StantonPyro", kind: "station", parent: @star, system: @system,
      position: [-1.0e10, 2.0e10, 0.0])
    create(:location, name: "Unplaced", sc_key: "Stanton1_Unplaced", kind: "outpost", parent: @hurston, system: @system)
  end

  test "GET /locations/{slug}/starmap lists the positioned places of the system from any place in it" do
    assert_api_response :get, 200, params: {slug: @hurston.slug} do
      assert_equal "Stanton System", parsed_body.dig("system", "name")
      assert_equal ["HUR-L1", "Pyro Gateway", "Hurston", "Stanton"].sort, parsed_body["places"].pluck("name").sort
    end
  end

  test "GET /locations/{slug}/starmap carries position, radius, parent and role" do
    assert_api_response :get, 200, params: {slug: @system.slug} do
      places = parsed_body["places"].index_by { |place| place["name"] }

      assert_equal [12_850_457_093.0, 0.0, 0.0], places.dig("Hurston", "position")
      assert_equal 1_000_000.0, places.dig("Hurston", "radius")
      assert_equal @star.id, places.dig("Hurston", "parentId")
      assert places.dig("HUR-L1", "lagrangePoint")
      assert places.dig("Pyro Gateway", "gateway")
      refute places.dig("Hurston", "gateway")
    end
  end

  test "GET /locations/{slug}/starmap reads the position of the served build" do
    @hurston.builds.sole.update!(position: [1.0, 2.0, 3.0])

    assert_api_response :get, 200, params: {slug: @system.slug} do
      assert_equal [1.0, 2.0, 3.0], parsed_body["places"].find { |place| place["name"] == "Hurston" }["position"]
    end
  end

  test "GET /locations/{slug}/starmap is a 404 for an unknown place" do
    assert_api_response :get, 404, params: {slug: "nowhere"}
  end
end
