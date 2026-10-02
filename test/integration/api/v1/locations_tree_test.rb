# frozen_string_literal: true

require "openapi_helper"

class Api::V1::LocationsTreeTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/locations/{slug}/tree" do
    get("Location system tree") do
      operationId "locationTree"
      tags "Locations"
      produces "application/json"

      parameter name: "slug", in: :path, schema: {type: :string}, required: true

      response(200, "successful") do
        schema ::V1::Schemas::LocationTreeNode
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @system = create(:location, name: "Stanton System", sc_key: "StantonSolarSystem", kind: "system")
    @star = create(:location, name: "Stanton", sc_key: "StantonStar", kind: "star", parent: @system, system: @system)
    @crusader = create(:location, name: "Crusader", sc_key: "Stanton2", kind: "planet", parent: @star, system: @system)
    @hurston = create(:location, name: "Hurston", sc_key: "Stanton1", kind: "planet", parent: @star, system: @system)
    @aberdeen = create(:location, name: "Aberdeen", sc_key: "Stanton1b", kind: "moon", parent: @hurston, system: @system)
    create(:location, name: "HUR L1", sc_key: "Stanton1_L1", kind: "asteroid", parent: @hurston, system: @system)
    create(:location, name: "Klescher Rehabilitation Facility", sc_key: "Klescher", kind: "outpost", parent: @aberdeen, system: @system)
    create(:location, name: "Pyro Gateway", sc_key: "RR_JP_StantonPyro", kind: "station", parent: @star, system: @system)
  end

  test "GET /locations/{slug}/tree draws the system from any place in it" do
    assert_api_response :get, 200, params: {slug: @aberdeen.slug} do
      star = parsed_body["children"].sole

      assert_equal "Stanton System", parsed_body.dig("location", "name")
      assert_equal ["Hurston", "Crusader"], star["children"].map { |node| node.dig("location", "name") }
      assert_equal ["Pyro Gateway"], star["gateways"].pluck("name")
    end
  end

  test "GET /locations/{slug}/tree counts what is not a body and lists Lagrange points" do
    assert_api_response :get, 200, params: {slug: @system.slug} do
      hurston = parsed_body["children"].sole["children"].first
      aberdeen = hurston["children"].sole

      assert_equal ["HUR L1"], hurston["lagrangePoints"].pluck("name")
      assert_equal [{"kind" => "outpost", "count" => 1}], aberdeen["counts"]
    end
  end

  test "GET /locations/{slug}/tree carries how a body is drawn" do
    @hurston.update!(color: "#a0522d")

    assert_api_response :get, 200, params: {slug: @system.slug} do
      hurston = parsed_body.dig("children", 0, "children").find { |node| node.dig("location", "name") == "Hurston" }

      assert_equal "#a0522d", hurston.dig("location", "color")
      assert_nil hurston.dig("location", "image")
    end
  end

  test "GET /locations/{slug}/tree answers 404 for an unknown place" do
    assert_api_response :get, 404, params: {slug: "port-olisar"}
  end
end
