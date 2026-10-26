# frozen_string_literal: true

require "openapi_helper"

class Api::V1::CartItemsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  SECURITY = [
    {SessionCookie: []},
    {Oauth2: ["hangar", "hangar:write"]},
    {OpenId: ["hangar", "hangar:write"]}
  ].freeze

  CART = ::V1::Schemas::Carts::Cart

  api_path "/cart/items" do
    post("Add Cart Item") do
      operationId "addCartItem"
      tags "Cart"
      consumes "application/json"
      produces "application/json"
      security SECURITY

      request_body required: true, schema: ::V1::Schemas::Inputs::CartItemCreateInput

      response(201, "successful") { schema CART }
      response(400, "validation error") { schema ::Shared::V1::Schemas::ValidationError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/cart/items/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

    put("Update Cart Item") do
      operationId "updateCartItem"
      tags "Cart"
      consumes "application/json"
      produces "application/json"
      security SECURITY

      request_body required: true, schema: ::V1::Schemas::Inputs::CartItemUpdateInput

      response(200, "successful") { schema CART }
      response(400, "validation error") { schema ::Shared::V1::Schemas::ValidationError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end

    delete("Remove Cart Item") do
      operationId "removeCartItem"
      tags "Cart"
      produces "application/json"
      security SECURITY

      response(200, "successful") { schema CART }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  setup do
    Flipper.enable(:shopping_cart)
    @user = create(:user)
    @commodity = create(:commodity, name: "Agricium")
    @cart_item = create(:cart_item, user: @user, item: @commodity, quantity: 4)
    sign_in @user
  end

  test "POST adds an item to the cart" do
    equipment = create(:equipment, name: "Adiva Jacket")

    assert_api_response :post, 201, api_path: "/cart/items",
      body: {itemType: "Equipment", itemId: equipment.id, quantity: 2} do
      line = parsed_body["items"].find { |entry| entry.dig("item", "id") == equipment.id }
      assert_equal [2, "Equipment"], [line["quantity"], line.dig("item", "type")]
    end
  end

  test "POST adds to the quantity of an item already in the cart" do
    assert_api_response :post, 201, api_path: "/cart/items",
      body: {itemType: "Commodity", itemId: @commodity.id, quantity: 3} do
      assert_equal [7], parsed_body["items"].pluck("quantity")
    end
  end

  test "POST rejects an item that does not exist" do
    assert_api_response :post, 400, api_path: "/cart/items",
      body: {itemType: "Component", itemId: SecureRandom.uuid}
  end

  test "POST rejects a quantity below one" do
    assert_api_response :post, 400, api_path: "/cart/items",
      body: {itemType: "Commodity", itemId: @commodity.id, quantity: -3}
    assert_equal 4, @cart_item.reload.quantity
  end

  test "POST is forbidden while the feature is off" do
    Flipper.disable(:shopping_cart)

    assert_api_response :post, 403, api_path: "/cart/items",
      body: {itemType: "Commodity", itemId: @commodity.id}
  end

  test "PUT changes the quantity" do
    assert_api_response :put, 200, api_path: "/cart/items/{id}",
      path_params: {id: @cart_item.id}, body: {quantity: 12} do
      assert_equal [12], parsed_body["items"].pluck("quantity")
    end
  end

  test "PUT pins the line to a place and unpins it again" do
    price = create(:item_price, item: @commodity, price_type: "sell", time_range: nil, price: 30)

    assert_api_response :put, 200, api_path: "/cart/items/{id}",
      path_params: {id: @cart_item.id}, body: {itemPriceId: price.id} do
      assert parsed_body.dig("items", 0, "pinned")
    end

    assert_api_response :put, 200, api_path: "/cart/items/{id}",
      path_params: {id: @cart_item.id}, body: {itemPriceId: nil} do
      assert_not parsed_body.dig("items", 0, "pinned")
    end
  end

  test "PUT rejects a price the item is not sold at" do
    price = create(:item_price, item: @commodity, price_type: "buy", time_range: nil, price: 30)

    assert_api_response :put, 400, api_path: "/cart/items/{id}",
      path_params: {id: @cart_item.id}, body: {itemPriceId: price.id}
  end

  test "PUT returns 404 for another user's item" do
    other = create(:cart_item)

    assert_api_response :put, 404, api_path: "/cart/items/{id}",
      path_params: {id: other.id}, body: {quantity: 2}
  end

  test "DELETE removes an item" do
    assert_api_response :delete, 200, api_path: "/cart/items/{id}", path_params: {id: @cart_item.id} do
      assert_empty parsed_body["items"]
    end
  end

  test "DELETE returns 404 for another user's item" do
    other = create(:cart_item)

    assert_api_response :delete, 404, api_path: "/cart/items/{id}", path_params: {id: other.id}
  end
end
