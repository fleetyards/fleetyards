# frozen_string_literal: true

require "openapi_helper"

class Api::V1::CartsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/cart" do
    get("Cart") do
      operationId "cart"
      parameter name: "strategy", in: :query, schema: ::V1::Schemas::Enums::CartStrategyEnum, required: false,
        description: "cheapest sends each line to its cheapest place; stops and distance shorten the trip"
      tags "Cart"
      produces "application/json"
      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") { schema ::V1::Schemas::Carts::Cart }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
    end

    delete("Clear Cart") do
      operationId "clearCart"
      tags "Cart"
      produces "application/json"
      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") { schema ::V1::Schemas::Carts::Cart }
    end
  end

  setup do
    Flipper.enable(:shopping_cart)
    @user = create(:user)

    system = create(:location, name: "Stanton System", kind: "system")
    hurston = create(:location, name: "Hurston", kind: "planet", parent: system, system:)
    everus = create(:location, name: "Everus Harbor", kind: "station", parent: hurston, system:)
    lorville = create(:location, name: "Lorville", kind: "city", parent: hurston, system:)
    casaba_everus = Shop.create!(name: "Casaba Outlet", location: everus)
    casaba_lorville = Shop.create!(name: "Casaba Outlet Lorville", location: lorville)
    terminal = create(:terminal, name: "Admin - Everus Harbor", location: everus)

    @hurston = hurston
    @casaba_lorville = casaba_lorville
    arccorp = create(:location, name: "ArcCorp", kind: "planet", parent: system, system:)
    area18 = create(:location, name: "Area18", kind: "city", parent: arccorp, system:)
    @area18_shop = Shop.create!(name: "Centermass", location: area18)

    @jacket = create(:equipment, name: "Adiva Jacket")

    @jacket_lorville = create(:item_price, item: @jacket, price_type: "sell", time_range: nil, price: 250, shop: casaba_lorville, location: "Casaba Outlet - Lorville")
    create(:item_price, item: @jacket, price_type: "sell", time_range: nil, price: 210, shop: casaba_everus, location: "Casaba Outlet - Everus Harbor")
    create(:item_price, item: @jacket, price_type: "buy", time_range: nil, price: 90, shop: casaba_everus, location: "Casaba Outlet - Everus Harbor")

    @agricium = create(:commodity, name: "Agricium")
    create(:item_price, item: @agricium, price_type: "sell", time_range: nil, price: 27.5, terminal:, location: "Admin - Everus Harbor")

    @cooler = create(:component, name: "Bracer")

    @jacket_line = create(:cart_item, user: @user, item: @jacket, quantity: 2)
    create(:cart_item, user: @user, item: @agricium, quantity: 10)
    create(:cart_item, user: @user, item: @cooler, quantity: 1)
  end

  test "GET /cart prices each line at its cheapest place and groups the lines by place" do
    create(:cart_item, item: @jacket)
    sign_in @user

    assert_api_response :get, 200, api_path: "/cart" do
      items = parsed_body["items"].index_by { |line| line.dig("item", "name") }
      assert_equal ["Adiva Jacket", "Agricium", "Bracer"], parsed_body["items"].map { |line| line.dig("item", "name") }
      assert_in_delta 420.0, items["Adiva Jacket"]["total"]
      assert_equal "Casaba Outlet", items["Adiva Jacket"].dig("price", "shop", "name")
      assert_equal 2, items["Adiva Jacket"]["offers"].size
      assert_in_delta 275.0, items["Agricium"]["total"]
      assert_not items["Bracer"]["available"]

      assert_equal [["Everus Harbor", "Stanton System", 695.0]],
        parsed_body["groups"].map { |group| group.values_at("name", "systemName", "subtotal") }
      assert_equal({"total" => 695.0, "itemsCount" => 3, "quantity" => 13, "unavailableCount" => 1, "stopsCount" => 1}, parsed_body["totals"])
    end
  end

  test "GET /cart shows the active list only" do
    create(:cart_item, cart: create(:cart, user: @user, active: false), item: create(:commodity))
    sign_in @user

    assert_api_response :get, 200, api_path: "/cart" do
      assert_equal 3, parsed_body["items"].size
    end
  end

  test "GET /cart is empty for a user without lists" do
    sign_in create(:user)

    assert_api_response :get, 200, api_path: "/cart" do
      assert_equal [nil, nil, false], parsed_body.values_at("id", "name", "active")
      assert_empty parsed_body["items"]
    end
  end

  test "GET /cart?strategy=stops buys at fewer places, paying more where it must" do
    helmet = create(:equipment, name: "Morozov Helmet")
    create(:item_price, item: helmet, price_type: "sell", time_range: nil, price: 90, shop: @area18_shop, location: "Centermass - Area18")
    create(:item_price, item: helmet, price_type: "sell", time_range: nil, price: 100, shop: @casaba_lorville, location: "Casaba Outlet - Lorville")
    create(:item_price, item: @cooler, price_type: "sell", time_range: nil, price: 500, shop: @casaba_lorville, location: "Casaba Outlet - Lorville")
    create(:cart_item, user: @user, item: helmet)
    sign_in @user

    get "/api/v1/cart"
    assert_equal ["Area18", "Everus Harbor", "Lorville"], parsed_body["groups"].pluck("name").sort

    assert_api_response :get, 200, api_path: "/cart", params: {strategy: "stops"} do
      assert_equal "stops", parsed_body["strategy"]
      assert_equal ["Everus Harbor", "Lorville"], parsed_body["groups"].pluck("name").sort
      helmet_line = parsed_body["items"].find { |line| line.dig("item", "name") == "Morozov Helmet" }
      assert_in_delta 100.0, helmet_line["unitPrice"]
      assert_not helmet_line["cheapest"]
    end
  end

  test "GET /cart?strategy=distance prefers a stop on a planet the trip already visits" do
    cooler_lorville = create(:item_price, item: @cooler, price_type: "sell", time_range: nil, price: 500, shop: @casaba_lorville, location: "Casaba Outlet - Lorville")
    outpost = create(:location, name: "HDMS-Edmond", kind: "outpost", parent: @hurston, system: @hurston.system)
    scanner = create(:equipment, name: "Scanner")
    create(:item_price, item: scanner, price_type: "sell", time_range: nil, price: 80, shop: @area18_shop, location: "Centermass - Area18")
    create(:item_price, item: scanner, price_type: "sell", time_range: nil, price: 95, shop: Shop.create!(name: "Outpost Shop", location: outpost), location: "Outpost Shop - HDMS-Edmond")
    create(:cart_item, user: @user, item: scanner)
    sign_in @user

    get "/api/v1/cart", params: {strategy: "stops"}
    assert_includes parsed_body["groups"].pluck("name"), "Area18"

    assert_api_response :get, 200, api_path: "/cart", params: {strategy: "distance"} do
      assert_equal ["Everus Harbor", "HDMS-Edmond", "Lorville"], parsed_body["groups"].pluck("name").sort
      assert_in_delta cooler_lorville.price, parsed_body["items"].find { |line| line.dig("item", "name") == "Bracer" }["unitPrice"]
    end
  end

  test "GET /cart keeps a pinned line where it is pinned whatever the strategy" do
    @jacket_line.update!(item_price: @jacket_lorville)
    sign_in @user

    assert_api_response :get, 200, api_path: "/cart", params: {strategy: "stops"} do
      jacket = parsed_body["items"].find { |line| line.dig("item", "name") == "Adiva Jacket" }
      assert jacket["pinned"]
      assert_in_delta 250.0, jacket["unitPrice"]
    end
  end

  test "GET /cart sends a pinned line to the place it is pinned to" do
    @jacket_line.update!(item_price: @jacket_lorville)
    sign_in @user

    assert_api_response :get, 200, api_path: "/cart" do
      assert_equal ["Everus Harbor", "Lorville"], parsed_body["groups"].pluck("name")
      assert(parsed_body["items"].find { |line| line["id"] == @jacket_line.id }["pinned"])
      assert_in_delta 775.0, parsed_body.dig("totals", "total")
    end
  end

  test "GET /cart groups a price we could not place under the name it came with" do
    lamp = create(:equipment, name: "Lamp")
    create(:item_price, item: lamp, price_type: "sell", time_range: nil, price: 5, location: "Somewhere - Unknown")
    create(:cart_item, user: @user, item: lamp)
    sign_in @user

    assert_api_response :get, 200, api_path: "/cart" do
      unplaced = parsed_body["groups"].find { |group| group["name"] == "Somewhere - Unknown" }
      assert_nil unplaced["location"]
    end
  end

  test "GET /cart is forbidden while the feature is off" do
    Flipper.disable(:shopping_cart)
    sign_in @user

    assert_api_response :get, 403, api_path: "/cart"
  end

  test "GET /cart returns 401 when not signed in" do
    assert_api_response :get, 401, api_path: "/cart"
  end

  test "DELETE /cart empties the user's active list only" do
    other = create(:cart_item)
    inactive = create(:cart_item, cart: create(:cart, user: @user, active: false))
    sign_in @user

    assert_api_response :delete, 200, api_path: "/cart" do
      assert_empty parsed_body["items"]
      assert_in_delta 0.0, parsed_body.dig("totals", "total")
    end
    assert CartItem.exists?(other.id)
    assert CartItem.exists?(inactive.id)
  end
end
