# frozen_string_literal: true

require "openapi_helper"

class Api::V1::SearchTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/search" do
    get("Search the catalogues") do
      operationId "search"
      tags "Search"
      produces "application/json"

      parameter name: "q", in: :query, schema: {type: :string}, required: true

      response(200, "successful") do
        schema ::V1::Schemas::SearchResults
      end
    end
  end

  test "GET /search finds items across the catalogues for a visitor" do
    ship = create(:model, name: "Omni Hauler")
    commodity = create(:commodity, name: "Omni Ore")

    assert_api_response :get, 200, params: {q: "omni"} do
      assert_equal(
        [["Model", [ship.slug]], ["Commodity", [commodity.slug]]],
        parsed_body["groups"].map { |group| [group["type"], group["items"].pluck("slug")] }
      )
    end
  end

  test "GET /search carries an item's picture where it has one" do
    create(:component, :with_store_image, name: "Omni Cannon")

    assert_api_response :get, 200, params: {q: "omni"} do
      image = parsed_body["groups"].first["items"].first["image"]

      assert_equal "test.png", image["name"]
      assert image["smallUrl"].present?
    end
  end

  test "GET /search tells how a place is drawn" do
    create(:location, name: "Omni Prime", kind: "planet", color: "#8fb8d0", body_type: "ice_giant")

    assert_api_response :get, 200, params: {q: "omni"} do
      appearance = parsed_body["groups"].first["items"].first["appearance"]

      assert_equal({"kind" => "planet", "color" => "#8fb8d0", "bodyType" => "ice_giant", "flare" => false}, appearance)
    end
  end

  test "GET /search answers nothing for a query too short to search" do
    create(:commodity, name: "Omni Ore")

    assert_api_response :get, 200, params: {q: "o"} do
      assert_empty parsed_body["groups"]
    end
  end
end
