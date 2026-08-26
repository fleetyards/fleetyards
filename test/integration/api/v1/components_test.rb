# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ComponentsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/components" do
    get("Components list") do
      operationId "components"
      tags "Components"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: Component.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {"$ref": "#/components/schemas/ComponentQuery"},
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, schema: {type: :string}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Components"
      end
    end
  end

  setup do
    @components = create_list(:component, 2)
  end

  test "GET /components lists all components" do
    assert_api_response :get, 200 do
      assert_equal 2, parsed_body.count
    end
  end

  test "GET /components filters by nameCont query" do
    assert_api_response :get, 200, params: {q: {"nameCont" => @components.first.name}} do
      items = parsed_body["items"]
      assert_equal 1, items.count
      assert_equal @components.first.name, items.first["name"]
    end
  end

  test "GET /components paginates with perPage" do
    assert_api_response :get, 200, params: {perPage: 2} do
      assert_equal 2, parsed_body.count
    end
  end

  test "GET /components filters by categoryIn query" do
    shield = create(:component, category: "shieldgenerator")
    create(:component, category: "cooler")

    assert_api_response :get, 200, params: {q: {"categoryIn" => ["shieldgenerator"]}} do
      items = parsed_body["items"]
      assert_equal 1, items.count
      assert_equal shield.name, items.first["name"]
    end
  end

  test "GET /components filters by componentSubTypeIn query" do
    missile = create(:component, category: "weapons", component_sub_type: "Missile")
    create(:component, category: "weapons", component_sub_type: "Gun")

    assert_api_response :get, 200, params: {q: {"componentSubTypeIn" => ["Missile"]}} do
      items = parsed_body["items"]
      assert_equal 1, items.count
      assert_equal missile.name, items.first["name"]
    end
  end

  test "GET /components filters by hiddenEq query" do
    visible = create(:component, category: "coolers")
    create(:component, :hidden, category: "coolers")

    assert_api_response :get, 200, params: {q: {"hiddenEq" => false, "categoryIn" => ["coolers"]}} do
      items = parsed_body["items"]
      assert_equal 1, items.count
      assert_equal visible.name, items.first["name"]
    end
  end

  test "GET /components filters out older game versions via currentVersion" do
    current = create(:component, category: "coolers", version: Rails.configuration.sc_data[:version])
    create(:component, category: "coolers", version: "0.0.1-live.1")

    assert_api_response :get, 200, params: {q: {"currentVersion" => true}} do
      items = parsed_body["items"]
      assert_equal 1, items.count
      assert_equal current.name, items.first["name"]
    end
  end
end
