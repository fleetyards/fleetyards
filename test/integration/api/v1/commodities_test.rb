# frozen_string_literal: true

require "openapi_helper"

class Api::V1::CommoditiesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/commodities" do
    get("Commodities list") do
      operationId "commodities"
      tags "Commodities"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Commodity.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::CommodityQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::V1::Schemas::Commodities::Commodities
      end
    end
  end

  setup do
    @gold = create(:commodity, name: "Gold", commodity_type: "metal")
    @laranite = create(:commodity, name: "Laranite", commodity_type: "mineral")
    @waste = create(:commodity, name: "Waste", commodity_type: "waste")
  end

  test "GET /commodities lists all commodities sorted by name" do
    assert_api_response :get, 200 do
      assert_equal %w[Gold Laranite Waste], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /commodities filters by nameCont" do
    assert_api_response :get, 200, params: {q: {"nameCont" => "aran"}} do
      assert_equal ["Laranite"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /commodities filters by commodityTypeIn" do
    assert_api_response :get, 200, params: {q: {"commodityTypeIn" => %w[metal mineral]}} do
      assert_equal %w[Gold Laranite], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /commodities paginates with perPage" do
    assert_api_response :get, 200, params: {perPage: 2} do
      assert_equal 2, parsed_body["items"].count
    end
  end

  test "GET /commodities leaves out commodities the current build no longer ships" do
    create(:commodity, name: "Astatine", version: "0.0.1-live.1")

    assert_api_response :get, 200 do
      assert_not_includes parsed_body["items"].map { |item| item["name"] }, "Astatine"
    end
  end

  test "GET /commodities includes older patches when currentVersion is false" do
    create(:commodity, name: "Astatine", version: "0.0.1-live.1")

    assert_api_response :get, 200, params: {q: {"currentVersion" => false}} do
      assert_includes parsed_body["items"].map { |item| item["name"] }, "Astatine"
    end
  end

  # Said out loud rather than left to be inferred from an absence: the list used
  # to serve a dropped commodity as though it were current.
  test "GET /commodities marks a commodity the current build no longer ships" do
    create(:commodity, name: "Astatine", version: "0.0.1-live.1")

    assert_api_response :get, 200, params: {q: {"currentVersion" => false}} do
      items = parsed_body["items"].index_by { |item| item["name"] }

      assert items["Astatine"]["retired"]
      assert_not items["Gold"]["retired"]
    end
  end

  # A retired commodity still has to read: an inventory ledger entry can point at
  # one, so the last build that described it answers rather than nothing.
  test "GET /commodities names a retired commodity off the last build describing it" do
    dropped = create(:commodity, :without_build, name: "Column Name", version: "0.0.1-live.1")
    create(:commodity_build, commodity: dropped, version: "0.0.1-live.1", name: "Astatine")

    assert_api_response :get, 200, params: {q: {"currentVersion" => false}} do
      assert_includes parsed_body["items"].map { |item| item["name"] }, "Astatine"
    end
  end

  test "GET /commodities exposes the fields the picker needs" do
    assert_api_response :get, 200 do
      gold = parsed_body["items"].find { |item| item["name"] == "Gold" }

      assert_equal @gold.id, gold["id"]
      assert_equal "gold", gold["slug"]
      assert_equal "metal", gold["commodityType"]
    end
  end

  # The UEX snapshot has priced commodities since it landed; until Commodity had
  # an item_prices association there was nothing to render them from.
  test "GET /commodities carries where a commodity is bought and sold" do
    create(:item_price, item: @gold, price_type: :buy, location: "Area18 TDD", price: 6_100)
    create(:item_price, item: @gold, price_type: :sell, location: "Lorville CBD", price: 6_450)

    assert_api_response :get, 200 do
      gold = parsed_body["items"].find { |item| item["name"] == "Gold" }

      assert_equal ["Area18 TDD"], gold["availability"]["boughtAt"].map { |price| price["location"] }
      assert_equal ["Lorville CBD"], gold["availability"]["soldAt"].map { |price| price["location"] }
      assert_equal "Commodity", gold["availability"]["boughtAt"].first["itemType"]
    end
  end

  # A vector has no representations to build, and a client that asks for a size
  # is every panel in the frontend -- they draw `smallUrl`, so leaving the sized
  # URLs out drops the icon back to the placeholder it used to fall through to.
  test "GET /commodities offers a vector icon at every size" do
    create(:commodity, :with_vector_store_image, name: "Aluminium")

    assert_api_response :get, 200 do
      image = parsed_body["items"].find { |item| item["name"] == "Aluminium" }["storeImage"]

      assert_equal "image/svg+xml", image["contentType"]
      assert_equal(
        [image["url"]] * 4,
        image.values_at("smallUrl", "mediumUrl", "largeUrl", "xlargeUrl")
      )
    end
  end

  test "GET /commodities carries empty availability for an unpriced commodity" do
    assert_api_response :get, 200 do
      waste = parsed_body["items"].find { |item| item["name"] == "Waste" }

      assert_empty waste["availability"]["boughtAt"]
      assert_empty waste["availability"]["soldAt"]
    end
  end
end
