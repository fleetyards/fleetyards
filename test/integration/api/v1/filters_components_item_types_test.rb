# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FiltersComponentsItemTypesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/components/item-types" do
    get("Components Item Types Filters") do
      operationId "componentItemTypesFilters"
      tags "ComponentsFilters"
      produces "application/json"

      # No component in the current build carries the column behind this list,
      # so every value it offers matches nothing. Kept answering because it is
      # public; the catalogue does not use it.
      deprecated true

      response(200, "successful") do
        schema ::Shared::V1::Schemas::FilterOptionsList
      end
    end
  end

  test "GET /filters/components/item-types returns filter options" do
    assert_api_response :get, 200 do
      assert_operator parsed_body.count, :>, 0
    end
  end
end
