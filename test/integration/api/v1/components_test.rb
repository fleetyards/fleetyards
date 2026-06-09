# frozen_string_literal: true

require_relative "../../../openapi_helper"

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
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ComponentQuery"
        },
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
end
