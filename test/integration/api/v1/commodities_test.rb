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

  # The two figures a row states, so it does not have to reduce the price arrays
  # itself -- and the columns the price sorts below order on.
  test "GET /commodities carries the cheapest price of each direction" do
    create(:item_price, item: @gold, price_type: :buy, location: "Area18 TDD", price: 6_100)
    create(:item_price, item: @gold, price_type: :buy, location: "Lorville CBD", price: 5_900)
    create(:item_price, item: @gold, price_type: :sell, location: "Area18 TDD", price: 6_450)

    assert_api_response :get, 200 do
      items = parsed_body["items"].index_by { |item| item["name"] }

      assert_equal 5_900.0, items["Gold"]["buyPrice"]
      assert_equal 6_450.0, items["Gold"]["sellPrice"]
      assert_nil items["Waste"]["buyPrice"]
    end
  end

  # The index overwrote whatever sort arrived with "name asc" until this branch,
  # so none of the paths below had ever run.
  test "GET /commodities sorts by name, both directions" do
    assert_api_response :get, 200, params: {q: {"sorts" => ["name desc"]}} do
      names = parsed_body["items"].map { |item| item["name"] }
      assert_equal names.sort.reverse, names
    end
  end

  # `q[s]` is what a sortable list actually sends; ransack reads it directly, so
  # a leftover would outrank the whitelisted `sorts`.
  test "GET /commodities accepts the s parameter as well as sorts" do
    assert_api_response :get, 200, params: {q: {"s" => "name desc"}} do
      names = parsed_body["items"].map { |item| item["name"] }
      assert_equal names.sort.reverse, names
    end
  end

  # A scalar subquery over `item_prices`, so ordering needs no join to undo --
  # and an unpriced commodity keeps its place in the list rather than being
  # filtered out by the sort. `MIN()` over no rows is NULL, which Postgres puts
  # last ascending.
  test "GET /commodities sorts by buyPrice and keeps the unpriced ones last" do
    create(:item_price, item: @gold, price_type: :buy, location: "Area18 TDD", price: 6_100)
    create(:item_price, item: @laranite, price_type: :buy, location: "Area18 TDD", price: 2_700)

    assert_api_response :get, 200, params: {q: {"sorts" => ["buyPrice asc"]}} do
      assert_equal %w[Laranite Gold Waste], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /commodities filters by a buy price range" do
    create(:item_price, item: @gold, price_type: :buy, location: "Area18 TDD", price: 6_100)
    create(:item_price, item: @laranite, price_type: :buy, location: "Area18 TDD", price: 2_700)

    assert_api_response :get, 200, params: {q: {"buyPriceGteq" => 3_000}} do
      assert_equal ["Gold"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  # "Nothing we know of trades this" is 108 of the 232, and a range filter
  # cannot ask it: an unpriced commodity is not cheap, it is unlisted.
  test "GET /commodities filters down to the commodities something buys" do
    create(:item_price, item: @gold, price_type: :buy, location: "Area18 TDD", price: 6_100)

    assert_api_response :get, 200, params: {q: {"buyPriceNotNull" => true}} do
      assert_equal ["Gold"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /commodities searches the description" do
    create(:commodity, name: "Astatine", description: "A halogen nobody wants to haul.")

    assert_api_response :get, 200, params: {q: {"descriptionCont" => "halogen"}} do
      assert_equal ["Astatine"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  # Each of these is dropped without a word if it is missing from
  # `ransackable_attributes` -- the sort simply does not appear in the SQL, and
  # the rows come back in whatever order the planner chose.
  #
  # Asserted as "descending is ascending reversed" rather than against a fixed
  # list: it needs no expected order written out per field, and a dropped sort
  # returns the same order both ways, which is exactly what it catches. A status
  # check alone would pass for every one of them.
  test "GET /commodities applies every sort the table offers" do
    [
      {name: "Sortprobe Aardvark", commodity_type: "alloy", buy: 100, sell: 900},
      {name: "Sortprobe Basilisk", commodity_type: "gas", buy: 200, sell: 800},
      {name: "Sortprobe Cormorant", commodity_type: "vice", buy: 300, sell: 700}
    ].each_with_index do |attrs, index|
      commodity = create(:commodity, name: attrs[:name], commodity_type: attrs[:commodity_type],
        sc_key: "sort_probe_#{index}")

      create(:item_price, item: commodity, price_type: :buy, location: "Probe", price: attrs[:buy])
      create(:item_price, item: commodity, price_type: :sell, location: "Probe", price: attrs[:sell])
    end

    %w[name commodityType buyPrice sellPrice createdAt updatedAt].each do |field|
      ascending = nil

      %w[asc desc].each do |direction|
        assert_api_response :get, 200, params: {
          # Scoped to the three probes: every other commodity in the set ties on
          # these fields, and ties do not reverse, so an unscoped comparison
          # would fail for a sort that works perfectly well.
          q: {"sorts" => ["#{field} #{direction}"], "nameCont" => "Sortprobe"}
        } do
          names = parsed_body["items"].map { |item| item["name"] }

          if direction == "asc"
            ascending = names
          else
            assert_equal ascending.reverse, names,
              "#{field} came back in the same order both ways, so the sort was dropped"
          end
        end
      end
    end
  end
end
