# frozen_string_literal: true

require "openapi_helper"

class Api::V1::CartListsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  READ = [
    {SessionCookie: []},
    {Oauth2: ["hangar", "hangar:read"]},
    {OpenId: ["hangar", "hangar:read"]}
  ].freeze

  WRITE = [
    {SessionCookie: []},
    {Oauth2: ["hangar", "hangar:write"]},
    {OpenId: ["hangar", "hangar:write"]}
  ].freeze

  api_path "/carts" do
    get("Cart Lists") do
      operationId "cartLists"
      tags "Cart"
      produces "application/json"
      security READ

      response(200, "successful") { schema ::V1::Schemas::Carts::CartListsList }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
    end

    post("Create Cart List") do
      operationId "createCartList"
      tags "Cart"
      consumes "application/json"
      produces "application/json"
      security WRITE

      request_body required: true, schema: ::V1::Schemas::Inputs::CartListCreateInput

      response(201, "successful") { schema ::V1::Schemas::Carts::CartList }
      response(400, "validation error") { schema ::Shared::V1::Schemas::ValidationError }
    end
  end

  api_path "/carts/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

    get("Cart List") do
      operationId "cartList"
      parameter name: "strategy", in: :query, schema: ::V1::Schemas::Enums::CartStrategyEnum, required: false,
        description: "cheapest sends each line to its cheapest place; stops and distance shorten the trip"
      tags "Cart"
      produces "application/json"
      security READ

      response(200, "successful") { schema ::V1::Schemas::Carts::Cart }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end

    put("Update Cart List") do
      operationId "updateCartList"
      tags "Cart"
      consumes "application/json"
      produces "application/json"
      security WRITE

      request_body required: true, schema: ::V1::Schemas::Inputs::CartListUpdateInput

      response(200, "successful") { schema ::V1::Schemas::Carts::CartList }
      response(400, "validation error") { schema ::Shared::V1::Schemas::ValidationError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end

    delete("Destroy Cart List") do
      operationId "destroyCartList"
      tags "Cart"
      produces "application/json"
      security WRITE

      response(200, "successful") { schema ::V1::Schemas::SuccessResponse }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/carts/{id}/items" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

    delete("Clear Cart List") do
      operationId "clearCartList"
      tags "Cart"
      produces "application/json"
      security WRITE

      response(200, "successful") { schema ::V1::Schemas::Carts::Cart }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  setup do
    Flipper.enable(:shopping_cart)
    @user = create(:user)
    @active = create(:cart, user: @user, name: "Mining run", created_at: 2.days.ago)
    @other = create(:cart, user: @user, name: "Bounty loadout", active: false)
    create(:cart_item, cart: @active, quantity: 3)
    create(:cart_item, cart: @active)
    sign_in @user
  end

  test "GET lists the user's lists with their line counts" do
    create(:cart)

    assert_api_response :get, 200, api_path: "/carts" do
      assert_equal [["Mining run", true, 2], ["Bounty loadout", false, 0]],
        parsed_body.map { |cart| cart.values_at("name", "active", "itemsCount") }
    end
  end

  test "GET is forbidden while the feature is off" do
    Flipper.disable(:shopping_cart)

    assert_api_response :get, 403, api_path: "/carts"
  end

  test "GET shows where to buy what is on a list that is not active" do
    create(:cart_item, cart: @other, quantity: 7)

    assert_api_response :get, 200, api_path: "/carts/{id}", path_params: {id: @other.id} do
      assert_equal [@other.id, "Bounty loadout", false], parsed_body.values_at("id", "name", "active")
      assert_equal [7], parsed_body["items"].pluck("quantity")
    end
  end

  test "GET returns 404 for another user's list" do
    assert_api_response :get, 404, api_path: "/carts/{id}", path_params: {id: create(:cart).id}
  end

  test "DELETE items empties that list only" do
    create(:cart_item, cart: @other)

    assert_api_response :delete, 200, api_path: "/carts/{id}/items", path_params: {id: @other.id} do
      assert_empty parsed_body["items"]
    end

    assert_equal 2, @active.cart_items.count
  end

  test "DELETE items returns 404 for another user's list" do
    assert_api_response :delete, 404, api_path: "/carts/{id}/items", path_params: {id: create(:cart).id}
  end

  test "POST creates a list and makes it the active one" do
    assert_api_response :post, 201, api_path: "/carts", body: {name: "Salvage"} do
      assert_equal ["Salvage", true, 0], parsed_body.values_at("name", "active", "itemsCount")
    end

    assert_not @active.reload.active?
  end

  test "POST rejects a name the user already has" do
    assert_api_response :post, 400, api_path: "/carts", body: {name: "Mining run"}
  end

  test "PUT renames a list" do
    assert_api_response :put, 200, api_path: "/carts/{id}",
      path_params: {id: @other.id}, body: {name: "Bounty kit"} do
      assert_equal ["Bounty kit", false], parsed_body.values_at("name", "active")
    end
  end

  test "PUT makes a list the active one" do
    assert_api_response :put, 200, api_path: "/carts/{id}",
      path_params: {id: @other.id}, body: {active: true} do
      assert parsed_body["active"]
    end

    assert_not @active.reload.active?
  end

  test "PUT returns 404 for another user's list" do
    assert_api_response :put, 404, api_path: "/carts/{id}",
      path_params: {id: create(:cart).id}, body: {active: true}
  end

  test "DELETE removes a list and its lines and hands active on" do
    assert_api_response :delete, 200, api_path: "/carts/{id}", path_params: {id: @active.id}

    assert_not Cart.exists?(@active.id)
    assert_empty CartItem.where(cart_id: @active.id)
    assert @other.reload.active?
  end

  test "DELETE returns 404 for another user's list" do
    assert_api_response :delete, 404, api_path: "/carts/{id}", path_params: {id: create(:cart).id}
  end
end
