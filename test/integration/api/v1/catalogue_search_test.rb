# frozen_string_literal: true

require "openapi_helper"

class Api::V1::CatalogueSearchTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/catalogue/search" do
    get("Search the catalogue for an item to name inline") do
      operationId "catalogueSearch"
      tags "Catalogue"
      produces "application/json"

      parameter name: :q, in: :query, schema: {type: :string}, required: true, description: "At least two characters of the name"

      response(200, "names that would resolve, each with the token to insert") do
        schema ::V1::Schemas::CatalogueTokenMatches
      end
    end
  end

  test "GET /catalogue/search offers names that resolve" do
    create(:commodity, name: "Quantainium")

    assert_api_response :get, 200, params: {q: "quant"} do
      assert_equal ["Quantainium"], parsed_body["items"].map { |item| item["token"] }
    end
  end
end
