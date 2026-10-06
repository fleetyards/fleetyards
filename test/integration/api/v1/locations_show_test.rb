# frozen_string_literal: true

require "openapi_helper"

class Api::V1::LocationsShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/locations/{slug}" do
    get("Location detail") do
      operationId "location"
      tags "Locations"
      produces "application/json"

      parameter name: "slug", in: :path, schema: {type: :string}, required: true

      response(200, "successful") do
        schema ::V1::Schemas::Location
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @system = create(:location, name: "Nyx System", kind: "system")
    @star = create(:location, name: "Nyx", kind: "star", parent: @system, system: @system)
    @delamar = create(:location, name: "Delamar", kind: "moon", parent: @star, system: @system)
    @levski = create(:location,
      name: "Levski", kind: "city", parent: @delamar, map_parent: @star, system: @system,
      description: "A self-sustaining port of political activists.", always_shown: true)
    create(:location, name: "Mercy Hospital", kind: "outpost", parent: @levski, system: @system, shown_on_starmap: false)
    create(:terminal, name: "Admin - Levski", location: @levski)
    create(:terminal, name: "Closed Kiosk - Levski", location: @levski, available: false)
  end

  test "GET /locations/{slug} returns the place where it sits and where the map draws it" do
    assert_api_response :get, 200, params: {slug: "levski"} do
      assert_equal "Levski", parsed_body["name"]
      assert_equal "city", parsed_body["kind"]
      assert_equal ["Nyx System", "Nyx", "Delamar"], parsed_body["ancestors"].pluck("name")
      assert_equal "Nyx", parsed_body.dig("mapParent", "name")
      assert parsed_body["alwaysShown"]
      assert_equal "A self-sustaining port of political activists.", parsed_body["description"]
    end
  end

  test "GET /locations/{slug} counts the places inside and names its terminals" do
    assert_api_response :get, 200, params: {slug: "levski"} do
      assert_equal 1, parsed_body["childrenCount"]
      assert_equal 4, parsed_body["placesCount"]
      assert_equal ["Admin - Levski"], parsed_body["terminals"].pluck("name")
    end
  end

  test "GET /locations/{slug} lists the hangars and pads a pilot can land in" do
    facilities = {
      "hangars" => [{"size" => "large", "door" => "front", "count" => 6, "length" => 128.0, "beam" => 72.0, "height" => 48.0}],
      "landing_pads" => [{"size" => "medium", "count" => 2, "atc_assigned" => false, "length" => 88.0, "beam" => 58.0, "height" => 32.0}],
      "vehicle_pads" => [],
      "docking_tubes" => 4
    }
    @levski.update!(facilities:)
    @levski.builds.update_all(facilities:)

    assert_api_response :get, 200, params: {slug: "levski"} do
      assert_equal [["large", "front", 6]], parsed_body.dig("facilities", "hangars").map { |hangar| hangar.values_at("size", "door", "count") }
      assert_equal [false], parsed_body.dig("facilities", "landingPads").pluck("atcAssigned")
      assert_equal 4, parsed_body.dig("facilities", "dockingTubes")
    end
  end

  test "GET /locations/{slug} leaves facilities empty where the game counts none" do
    assert_api_response :get, 200, params: {slug: "delamar"} do
      assert_nil parsed_body["facilities"]
    end
  end

  test "GET /locations/{slug} leaves the map parent empty where it is the parent" do
    assert_api_response :get, 200, params: {slug: "delamar"} do
      assert_nil parsed_body["mapParent"]
    end
  end

  test "GET /locations/{slug} lists what can be found there, linked to the commodity" do
    aluminum = create(:commodity, name: "Aluminum")
    resources = [
      {"kind" => "ship_mineables", "items" => [{"name" => "Aluminum", "note" => nil}]},
      {"kind" => "hand_mineables", "items" => [{"name" => "Janalite", "note" => "Caves only"}]}
    ]
    @delamar.update!(resources:)
    @delamar.builds.update_all(resources:)

    assert_api_response :get, 200, params: {slug: "delamar"} do
      ship, hand = parsed_body["resources"]

      assert_equal "ship_mineables", ship["kind"]
      assert_equal aluminum.slug, ship["items"].sole.dig("commodity", "slug")
      assert_equal ["Janalite", "Caves only", nil], hand["items"].sole.values_at("name", "note", "commodity")
    end
  end

  test "GET /locations/{slug} links a resource by the name the build gives the commodity" do
    ore = create(:commodity, name: "Old Ore")
    ore.builds.update_all(name: "New Ore")
    resources = [{"kind" => "ship_mineables", "items" => [{"name" => "New Ore", "note" => nil}]}]
    @delamar.update!(resources:)
    @delamar.builds.update_all(resources:)

    assert_api_response :get, 200, params: {slug: "delamar"} do
      assert_equal ore.slug, parsed_body["resources"].first["items"].sole.dig("commodity", "slug")
    end
  end

  test "GET /locations/{slug} answers 404 for an unknown place" do
    assert_api_response :get, 404, params: {slug: "port-olisar"}
  end
end
