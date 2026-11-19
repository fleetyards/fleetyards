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
      refute places.dig("Pyro Gateway", "docking")
    end
  end

  test "GET /locations/{slug}/starmap lists what a place offers" do
    @gateway.builds.sole.update!(amenities: %w[vehicle_services docking])

    assert_api_response :get, 200, params: {slug: @system.slug} do
      places = parsed_body["places"].index_by { |place| place["name"] }

      assert_equal %w[vehicle_services docking], places.dig("Pyro Gateway", "amenities")
      assert_equal [], places.dig("Hurston", "amenities")
    end
  end

  test "GET /locations/{slug}/starmap carries how a body is drawn" do
    @hurston.update!(color: "#9c846e", body_type: "gas_giant")
    @hurston.builds.sole.update!(body_type: "gas_giant")

    assert_api_response :get, 200, params: {slug: @system.slug} do
      hurston = parsed_body["places"].find { |place| place["name"] == "Hurston" }

      assert_equal "#9c846e", hurston["color"]
      assert_equal "gas_giant", hurston["bodyType"]
    end
  end

  test "GET /locations/{slug}/starmap serves a body's starmap texture where it has one" do
    @hurston.surfaces.create!(environment: ScData::Source.environment).texture.attach(
      io: File.open(Rails.root.join("test/fixtures/sc_data/parsed/test/starmap_materials/ui_sm_stanton_1_hurston.webp")),
      filename: "ui_sm_stanton_1_hurston.webp",
      content_type: "image/webp"
    )

    assert_api_response :get, 200, params: {slug: @system.slug} do
      places = parsed_body["places"].index_by { |place| place["name"] }

      assert_equal "ui_sm_stanton_1_hurston.webp", places.dig("Hurston", "texture", "name")
      assert places.dig("Hurston", "texture", "url").present?
      assert_nil places.dig("Stanton", "texture")
      assert_nil places.dig("Hurston", "elevation")
      assert_nil places.dig("Hurston", "clouds")
    end
  end

  test "GET /locations/{slug}/starmap shows only the served environment's images where it has any" do
    @hurston.surfaces.create!(environment: ScData::Source.environment).elevation.attach(
      io: StringIO.new("served"), filename: "served.png", content_type: "image/png"
    )
    @hurston.surfaces.create!(environment: "elsewhere").texture.attach(
      io: StringIO.new("other"), filename: "other.webp", content_type: "image/webp"
    )

    assert_api_response :get, 200, params: {slug: @system.slug} do
      hurston = parsed_body["places"].find { |place| place["name"] == "Hurston" }

      assert_equal "served.png", hurston.dig("elevation", "name")
      assert_nil hurston["texture"]
    end
  end

  test "GET /locations/{slug}/starmap borrows another environment's images where it has none" do
    @hurston.surfaces.create!(environment: "elsewhere").texture.attach(
      io: StringIO.new("other"), filename: "other.webp", content_type: "image/webp"
    )

    assert_api_response :get, 200, params: {slug: @system.slug} do
      hurston = parsed_body["places"].find { |place| place["name"] == "Hurston" }

      assert_equal "other.webp", hurston.dig("texture", "name")
    end
  end

  test "GET /locations/{slug}/starmap places a body the served build does not where an older build did" do
    @hurston.builds.sole.update!(position: nil, radius: nil)
    @hurston.builds.create!(environment: "elsewhere", version: "0.9.0", position: [1.0, 2.0, 3.0], radius: 5.0)

    assert_api_response :get, 200, params: {slug: @system.slug} do
      hurston = parsed_body["places"].find { |place| place["name"] == "Hurston" }

      assert_equal [1.0, 2.0, 3.0], hurston["position"]
      assert_equal 5.0, hurston["radius"]
    end
  end

  test "GET /locations/{slug}/starmap says where a ship can dock" do
    @gateway.builds.sole.update!(facilities: {"hangars" => [{"size" => "large", "count" => 2}], "landing_pads" => []})

    assert_api_response :get, 200, params: {slug: @system.slug} do
      assert parsed_body["places"].find { |place| place["name"] == "Pyro Gateway" }["docking"]
    end
  end

  test "GET /locations/{slug}/starmap counts landing pads and docking collars as somewhere to dock" do
    @gateway.builds.sole.update!(facilities: {"hangars" => [], "landing_pads" => [{"size" => "medium", "count" => 1}]})

    assert_api_response :get, 200, params: {slug: @system.slug} do
      assert parsed_body["places"].find { |place| place["name"] == "Pyro Gateway" }["docking"]
    end

    @gateway.builds.sole.update!(facilities: {"hangars" => [], "landing_pads" => [], "docking_tubes" => 2})

    assert_api_response :get, 200, params: {slug: @system.slug} do
      assert parsed_body["places"].find { |place| place["name"] == "Pyro Gateway" }["docking"]
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
