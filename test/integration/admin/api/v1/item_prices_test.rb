# frozen_string_literal: true

require_relative "../../../../openapi_helper"

class Admin::Api::V1::ItemPricesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  # Operation order matches the alphabetical load order of the original
  # spec files (create, destroy, index, show, update).

  api_path "/item-prices" do
    post("Create new Item Price") do
      operationId "createItemPrice"
      tags "ItemPrices"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ItemPriceInput"}

      response(201, "successful") do
        schema "$ref": "#/components/schemas/ItemPrice"
      end

      response(400, "unauthorized") do
        schema "$ref": "#/components/schemas/ValidationError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    get("Item Prices list") do
      operationId "itemPrices"
      tags "ItemPrices"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: ItemPrice.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ItemPriceQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ItemPrices"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/item-prices/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    delete("Item price destroy") do
      operationId "destroyItemPrice"
      tags "ItemPrices"

      response(204, "successful")

      response(404, "not_found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    get("Get Item Price") do
      operationId "itemPrice"
      tags "ItemPrices"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ItemPrice"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    put("Update Item Price") do
      operationId "updateItemPrice"
      tags "ItemPrices"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ItemPriceInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ItemPrice"
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @user = create(:admin_user, resource_access: [:item_prices])
  end

  def valid_body(item = nil)
    item ||= create(:model)
    {
      itemId: item.id,
      itemType: item.class.name,
      price: 1000.50,
      priceType: "buy",
      location: "Port Olisar"
    }
  end

  # POST
  test "POST /item-prices creates a price" do
    sign_in @user

    assert_api_response :post, 201, body: valid_body
  end

  test "POST /item-prices returns 400 for missing body" do
    sign_in @user

    assert_api_response :post, 400, body: nil
  end

  test "POST /item-prices returns 401 when not signed in" do
    assert_api_response :post, 401, body: valid_body
  end

  test "POST /item-prices returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, body: valid_body
  end

  # GET list
  test "GET /item-prices lists prices" do
    create_list(:item_price, 10)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 10, parsed_body["items"].count
    end
  end

  test "GET /item-prices filters by itemIdEq" do
    prices = create_list(:item_price, 10)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"itemIdEq" => prices.first.item_id}} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /item-prices returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /item-prices returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  # DELETE
  test "DELETE /item-prices/:id destroys the price" do
    price = create(:item_price)
    sign_in @user

    assert_api_response :delete, 204, path_params: {id: price.id}
  end

  test "DELETE /item-prices/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end

  test "DELETE /item-prices/:id returns 401 when not signed in" do
    price = create(:item_price)

    assert_api_response :delete, 401, path_params: {id: price.id}
  end

  test "DELETE /item-prices/:id returns 403 for admin without access" do
    price = create(:item_price)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: price.id}
  end

  # GET single
  test "GET /item-prices/:id returns the price" do
    price = create(:item_price)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: price.id}
  end

  test "GET /item-prices/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}
  end

  test "GET /item-prices/:id returns 401 when not signed in" do
    price = create(:item_price)

    assert_api_response :get, 401, path_params: {id: price.id}
  end

  test "GET /item-prices/:id returns 403 for admin without access" do
    price = create(:item_price)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: price.id}
  end

  # PUT
  test "PUT /item-prices/:id updates the price" do
    price = create(:item_price)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: price.id}, body: {price: 500}
  end

  test "PUT /item-prices/:id returns 400 for invalid price_type" do
    price = create(:item_price)
    sign_in @user

    assert_api_response :put, 400, path_params: {id: price.id}, body: {price_type: "foo"}
  end

  test "PUT /item-prices/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}, body: {price: 500}
  end

  test "PUT /item-prices/:id returns 401 when not signed in" do
    price = create(:item_price)

    assert_api_response :put, 401, path_params: {id: price.id}, body: {price: 500}
  end

  test "PUT /item-prices/:id returns 403 for admin without access" do
    price = create(:item_price)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: price.id}, body: {price: 500}
  end
end
