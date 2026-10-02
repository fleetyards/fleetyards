# frozen_string_literal: true

require "openapi_helper"

class Api::V1::LocationsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/locations" do
    get("Locations list") do
      operationId "locations"
      tags "Locations"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Location.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::LocationQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::V1::Schemas::Locations
      end
    end
  end

  setup do
    @system = create(:location, name: "Stanton System", kind: "system")
    @star = create(:location, name: "Stanton", kind: "star", parent: @system, system: @system)
    @hurston = create(:location, name: "Hurston", kind: "planet", parent: @star, system: @system)
    @lorville = create(:location, name: "Lorville", kind: "city", parent: @hurston, system: @system, shown_with_parent_only: true)
    @retired = create(:location, name: "Port Olisar", version: nil, with_build: false)
  end

  test "GET /locations lists the places the build carries" do
    assert_api_response :get, 200 do
      names = parsed_body["items"].pluck("name")

      assert_equal ["Hurston", "Lorville", "Stanton", "Stanton System"], names
      assert_not_includes names, "Port Olisar"
    end
  end

  test "GET /locations lists the places inside one" do
    assert_api_response :get, 200, params: {q: {parentIdEq: @hurston.id}} do
      assert_equal ["Lorville"], parsed_body["items"].pluck("name")
      assert_equal "Hurston", parsed_body["items"].first.dig("parent", "name")
      assert_equal "Stanton", parsed_body["items"].first.dig("parent", "parentName")
    end
  end

  test "GET /locations filters by kind" do
    assert_api_response :get, 200, params: {q: {kindEq: "system"}} do
      assert_equal ["Stanton System"], parsed_body["items"].pluck("name")
      assert_nil parsed_body["items"].first["parent"]
    end
  end

  test "GET /locations leaves out a hidden system and what is in it" do
    ellis = create(:location, name: "Ellis System", kind: "system", sc_key: "EllisSolarSystem")
    create(:location, name: "Green", kind: "planet", parent: @star, system: ellis)

    assert_api_response :get, 200 do
      names = parsed_body["items"].pluck("name")

      assert_not_includes names, "Ellis System"
      assert_not_includes names, "Green"
      assert_includes names, "Hurston"
    end
  end
end
