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
      assert_equal ["Admin - Levski"], parsed_body["terminals"].pluck("name")
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

  test "GET /locations/{slug} answers 404 for an unknown place" do
    assert_api_response :get, 404, params: {slug: "port-olisar"}
  end
end
