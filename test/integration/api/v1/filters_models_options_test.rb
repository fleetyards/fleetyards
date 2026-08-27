# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FiltersModelsOptionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/models/options" do
    get("Model Options") do
      operationId "modelOptions"
      tags "ModelsFilters"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Model.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::ModelQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::V1::Schemas::Models::Options::ModelOptions
      end
    end
  end

  test "GET /filters/models/options returns the picker payload for each model" do
    model = create(:model, :with_store_image)

    assert_api_response :get, 200 do
      item = parsed_body["items"].find { |entry| entry["id"] == model.id }

      assert_equal(
        %w[id name slug manufacturer classification classificationLabel inHangar onWishlist media].sort,
        item.keys.sort
      )
      assert_equal %w[name slug code].sort, item["manufacturer"].keys.sort
      assert_equal model.manufacturer.slug, item["manufacturer"]["slug"]
    end
  end

  test "GET /filters/models/options filters by nameCont" do
    models = create_list(:model, 6, :with_store_image)

    assert_api_response :get, 200, params: {q: {"nameCont" => models.first.name}} do
      items = parsed_body["items"]
      assert_equal 1, items.count
      assert_equal models.first.name, items.first["name"]
    end
  end

  test "GET /filters/models/options filters by manufacturerIn" do
    model = create(:model, :with_store_image)
    create_list(:model, 2, :with_store_image)

    assert_api_response :get, 200, params: {q: {"manufacturerIn" => [model.manufacturer.slug]}} do
      items = parsed_body["items"]

      assert_equal [model.id], items.map { |item| item["id"] }
    end
  end

  test "GET /filters/models/options filters by classificationIn" do
    combat = create(:model, :with_store_image, classification: "combat")
    create_list(:model, 2, :with_store_image, classification: "multi_role")

    assert_api_response :get, 200, params: {q: {"classificationIn" => ["combat"]}} do
      items = parsed_body["items"]

      assert_includes items.map { |item| item["id"] }, combat.id
      assert_equal ["combat"], items.map { |item| item["classification"] }.uniq
      assert_equal ["Combat"], items.map { |item| item["classificationLabel"] }.uniq
    end
  end

  test "GET /filters/models/options marks models the signed in user owns or wants" do
    owned, wished, untouched = create_list(:model, 3, :with_store_image)
    user = create(:user)
    create(:vehicle, user:, model: owned)
    create(:vehicle, :wanted, user:, model: wished)
    sign_in user

    assert_api_response :get, 200 do
      flags = parsed_body["items"].to_h { |item| [item["id"], item.slice("inHangar", "onWishlist")] }

      assert_equal({"inHangar" => true, "onWishlist" => false}, flags[owned.id])
      assert_equal({"inHangar" => false, "onWishlist" => true}, flags[wished.id])
      assert_equal({"inHangar" => false, "onWishlist" => false}, flags[untouched.id])
    end
  end

  test "GET /filters/models/options reports no hangar flags when signed out" do
    model = create(:model, :with_store_image)
    create(:vehicle, model:)

    assert_api_response :get, 200 do
      item = parsed_body["items"].find { |entry| entry["id"] == model.id }

      assert_equal false, item["inHangar"]
      assert_equal false, item["onWishlist"]
    end
  end
end
