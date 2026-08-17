# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::CommoditiesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/commodities" do
    post("Create Commodity") do
      operationId "createCommodity"
      tags "Commodities"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/CommodityInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Commodity"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    get("Commodities list") do
      operationId "commodities"
      tags "Commodities"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Commodity.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/CommodityQuery"
        },
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, schema: {type: :string}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Commodities"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/commodities/{id}" do
    parameter name: "id", in: :path, description: "Commodity id", schema: {type: :string, format: :uuid}, required: true

    delete("Destroy Commodity") do
      operationId "destroyCommodity"
      tags "Commodities"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Commodity"
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

    get("Commodity Detail") do
      operationId "commodity"
      tags "Commodities"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Commodity"
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

    put("Update Commodity") do
      operationId "updateCommodity"
      tags "Commodities"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/CommodityInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Commodity"
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
    @user = create(:admin_user, resource_access: [:commodities])
  end

  # POST /commodities
  test "POST /commodities creates a commodity" do
    sign_in @user

    assert_api_response :post, 200, api_path: "/commodities", body: {name: "Laranite"} do
      assert_equal "Laranite", parsed_body["name"]
    end
  end

  # See the equipment test: the request contract is camelCase, the permit list is
  # snake_case, and Middleware::TransformParameters is what joins them. Only a
  # multi-word field exercises it.
  test "POST /commodities accepts the camelCase fields the schema declares" do
    sign_in @user

    body = {
      name: "Laranite",
      commodityType: "mineral",
      uexId: 42,
      uexCode: "LARA",
      scKey: "test_commodity_laranite"
    }

    assert_api_response :post, 200, api_path: "/commodities", body: body do
      assert_equal "mineral", parsed_body["commodityType"]
      assert_equal 42, parsed_body["uexId"]
      assert_equal "LARA", parsed_body["uexCode"]

      created = Commodity.find(parsed_body["id"])
      assert_equal "test_commodity_laranite", created.sc_key
    end
  end

  test "POST /commodities returns 401 when not signed in" do
    assert_api_response :post, 401, api_path: "/commodities", body: {name: "x"}
  end

  test "POST /commodities returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, api_path: "/commodities", body: {name: "x"}
  end

  # GET /commodities
  test "GET /commodities lists commodities" do
    create_list(:commodity, 2)
    create(:commodity, name: "Laranite")
    sign_in @user

    assert_api_response :get, 200, api_path: "/commodities" do
      assert_equal 3, parsed_body["items"].count
    end
  end

  # The public list narrows to current_version; the admin one must not, or a
  # commodity a patch dropped becomes uneditable.
  test "GET /commodities includes commodities from past versions" do
    create(:commodity, name: "Retired Ore", version: "3.0.0")
    sign_in @user

    assert_api_response :get, 200, api_path: "/commodities" do
      assert_equal ["Retired Ore"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /commodities filters by nameCont query" do
    create_list(:commodity, 2)
    create(:commodity, name: "Laranite")
    sign_in @user

    assert_api_response :get, 200, api_path: "/commodities", params: {q: {"nameCont" => "Laran"}} do
      items = parsed_body["items"]
      assert_equal 1, items.count
      assert_equal "Laranite", items.first["name"]
    end
  end

  test "GET /commodities filters by commodityTypeIn query" do
    create(:commodity, name: "Steel")
    create(:commodity, :mineral, name: "Quartz")
    sign_in @user

    assert_api_response :get, 200, api_path: "/commodities", params: {q: {"commodityTypeIn" => ["mineral"]}} do
      items = parsed_body["items"]
      assert_equal 1, items.count
      assert_equal "Quartz", items.first["name"]
    end
  end

  test "GET /commodities carries the cheapest price of each direction" do
    commodity = create(:commodity, name: "Laranite")
    create(:item_price, item: commodity, price_type: :buy, price: 31.1)
    create(:item_price, item: commodity, price_type: :sell, price: 29.85)
    create(:item_price, item: commodity, price_type: :sell, price: 40)
    sign_in @user

    assert_api_response :get, 200, api_path: "/commodities" do
      item = parsed_body["items"].first

      assert_in_delta 31.1, item["buyPrice"]
      assert_in_delta 29.85, item["sellPrice"]
    end
  end

  test "GET /commodities leaves the prices null when nothing quotes one" do
    create(:commodity)
    sign_in @user

    assert_api_response :get, 200, api_path: "/commodities" do
      item = parsed_body["items"].first

      assert_nil item["buyPrice"]
      assert_nil item["sellPrice"]
    end
  end

  test "GET /commodities filters by a buy price range" do
    cheap = create(:commodity, name: "Scrap")
    create(:item_price, item: cheap, price_type: :buy, price: 5)
    dear = create(:commodity, name: "Quantanium")
    create(:item_price, item: dear, price_type: :buy, price: 88)
    sign_in @user

    query = {q: {"buyPriceGteq" => 50, "buyPriceLteq" => 100}}

    assert_api_response :get, 200, api_path: "/commodities", params: query do
      assert_equal ["Quantanium"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /commodities filters by a sell price range" do
    cheap = create(:commodity, name: "Scrap")
    create(:item_price, item: cheap, price_type: :sell, price: 5)
    dear = create(:commodity, name: "Quantanium")
    create(:item_price, item: dear, price_type: :sell, price: 88)
    sign_in @user

    assert_api_response :get, 200, api_path: "/commodities", params: {q: {"sellPriceLteq" => 10}} do
      assert_equal ["Scrap"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /commodities sorts by name descending" do
    create(:commodity, name: "Agricium")
    create(:commodity, name: "Titanium")
    sign_in @user

    assert_api_response :get, 200, api_path: "/commodities", params: {q: {"sorts" => ["name desc"]}} do
      assert_equal ["Titanium", "Agricium"], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /commodities paginates with perPage" do
    create_list(:commodity, 3)
    sign_in @user

    assert_api_response :get, 200, api_path: "/commodities", params: {perPage: 2} do
      assert_equal 2, parsed_body["items"].count
    end
  end

  test "GET /commodities returns 401 when not signed in" do
    assert_api_response :get, 401, api_path: "/commodities"
  end

  test "GET /commodities returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, api_path: "/commodities"
  end

  # DELETE /commodities/:id
  test "DELETE /commodities/:id destroys the commodity" do
    commodity = create(:commodity)
    sign_in @user

    assert_api_response :delete, 200, path_params: {id: commodity.id}
  end

  test "DELETE /commodities/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
  end

  test "DELETE /commodities/:id returns 401 when not signed in" do
    commodity = create(:commodity)

    assert_api_response :delete, 401, path_params: {id: commodity.id}
  end

  test "DELETE /commodities/:id returns 403 for admin without access" do
    commodity = create(:commodity)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: commodity.id}
  end

  # GET /commodities/:id
  test "GET /commodities/:id returns the commodity" do
    commodity = create(:commodity)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: commodity.id}, api_path: "/commodities/{id}"
  end

  test "GET /commodities/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: SecureRandom.uuid}, api_path: "/commodities/{id}"
  end

  test "GET /commodities/:id returns 401 when not signed in" do
    commodity = create(:commodity)

    assert_api_response :get, 401, path_params: {id: commodity.id}, api_path: "/commodities/{id}"
  end

  test "GET /commodities/:id returns 403 for admin without access" do
    commodity = create(:commodity)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: commodity.id}, api_path: "/commodities/{id}"
  end

  # PUT /commodities/:id
  test "PUT /commodities/:id updates the commodity" do
    commodity = create(:commodity)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: commodity.id}, body: {name: "Updated Ore"} do
      assert_equal "Updated Ore", parsed_body["name"]
    end
  end

  test "PUT /commodities/:id updates the UEX mapping" do
    commodity = create(:commodity)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: commodity.id}, body: {uexId: 42, uexCode: "LARA"} do
      assert_equal 42, parsed_body["uexId"]
      assert_equal "LARA", parsed_body["uexCode"]
    end
  end

  test "PUT /commodities/:id attaches a store image" do
    commodity = create(:commodity)
    sign_in @user

    blob = ActiveStorage::Blob.create_and_upload!(
      io: Rails.root.join("test/fixtures/files/test.png").open,
      filename: "test.png",
      content_type: "image/png"
    )

    assert_api_response :put, 200, path_params: {id: commodity.id}, body: {storeImage: blob.signed_id} do
      assert parsed_body["storeImage"]["url"].present?
    end

    assert_predicate commodity.reload.store_image, :attached?
  end

  test "PUT /commodities/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}, body: {name: "x"}
  end

  test "PUT /commodities/:id returns 401 when not signed in" do
    commodity = create(:commodity)

    assert_api_response :put, 401, path_params: {id: commodity.id}, body: {name: "x"}
  end

  test "PUT /commodities/:id returns 403 for admin without access" do
    commodity = create(:commodity)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: commodity.id}, body: {name: "x"}
  end
end
