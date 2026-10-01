# frozen_string_literal: true

require "openapi_helper"

class Api::V1::CatalogueLookupTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/catalogue/lookup" do
    get("Resolve the catalogue items a text names inline") do
      operationId "catalogueLookup"
      tags "Catalogue"
      produces "application/json"

      parameter name: :names, in: :query, schema: {type: :array, items: {type: :string}, maxItems: 100}, style: :form, explode: true, required: true,
        description: "Token texts: `Name` or `type:Name`, type being component, equipment or commodity"

      response(200, "the names that resolve to exactly one listed item") do
        schema ::V1::Schemas::CatalogueTokenMatches
      end
    end
  end

  test "GET /catalogue/lookup resolves a name to its one item" do
    commodity = create(:commodity, name: "Quantainium")

    assert_api_response :get, 200, params: {names: ["Quantainium", "Nothing By This Name"]} do
      assert_equal [{"token" => "Quantainium", "name" => "Quantainium", "type" => "Commodity", "slug" => commodity.slug}], parsed_body["items"]
    end
  end
end
