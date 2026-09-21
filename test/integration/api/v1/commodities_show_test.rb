# frozen_string_literal: true

require "openapi_helper"

class Api::V1::CommoditiesShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/commodities/{slug}" do
    get("Commodity detail") do
      operationId "commodity"
      tags "Commodities"
      produces "application/json"

      parameter name: :slug, in: :path, schema: {type: :string}, required: true

      response(200, "successful") do
        schema ::V1::Schemas::Commodity
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @gold = create(:commodity, name: "Gold", commodity_type: "metal")
  end

  test "GET /commodities/{slug} returns the commodity" do
    assert_api_response :get, 200, params: {slug: @gold.slug} do
      assert_equal "Gold", parsed_body["name"]
      assert_equal "gold", parsed_body["slug"]
      assert_equal "metal", parsed_body["commodityType"]
    end
  end

  # The whole point of the endpoint: the detail page opens on the terminals and
  # the two figures, and reducing the arrays client-side is what the scalars
  # exist to avoid.
  test "GET /commodities/{slug} carries the terminals and the cheapest of each direction" do
    create(:item_price, item: @gold, price_type: :buy, location: "Area18 TDD", price: 6_100)
    create(:item_price, item: @gold, price_type: :buy, location: "Lorville CBD", price: 5_900)
    create(:item_price, item: @gold, price_type: :sell, location: "Area18 TDD", price: 6_450)

    assert_api_response :get, 200, params: {slug: @gold.slug} do
      assert_equal 5_900.0, parsed_body["buyPrice"]
      assert_equal 6_450.0, parsed_body["sellPrice"]
      assert_equal ["Lorville CBD", "Area18 TDD"],
        parsed_body["availability"]["boughtAt"].map { |price| price["location"] }
    end
  end

  # Null rather than zero, and the page turns that into a sentence. Half the
  # catalogue is priced nowhere, so this is the common case, not the edge.
  test "GET /commodities/{slug} leaves both prices null when nothing trades it" do
    assert_api_response :get, 200, params: {slug: @gold.slug} do
      assert_nil parsed_body["buyPrice"]
      assert_nil parsed_body["sellPrice"]
      assert_empty parsed_body["availability"]["boughtAt"]
    end
  end

  # Unscoped by build, unlike the list. An inventory ledger entry can point at a
  # commodity a later patch dropped, so the link has to keep resolving -- and
  # `retired` is what tells the page not to render the figures as current.
  test "GET /commodities/{slug} still resolves a commodity the current build dropped" do
    dropped = create(:commodity, name: "Astatine", version: "0.0.1-live.1")

    assert_api_response :get, 200, params: {slug: dropped.slug} do
      assert_equal "Astatine", parsed_body["name"]
      assert parsed_body["retired"]
    end
  end

  # A literal slug rather than a generated one: the factory names commodities
  # from Faker, which has drawn a name containing the probe string before.
  test "GET /commodities/{slug} 404s for a slug nobody has" do
    assert_api_response :get, 404, params: {slug: "no-such-commodity-at-all"}
  end
end
