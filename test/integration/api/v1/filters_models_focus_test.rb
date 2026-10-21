# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FiltersModelsFocusTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/models/focus" do
    get("Model focus Filters") do
      operationId "modelFocusFilters"
      tags "ModelsFilters"
      produces "application/json"

      parameter name: :classification, in: :query, schema: {type: :string}, required: false,
        description: "Restrict the result to focuses of models with this classification"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::FilterOptionsList
      end
    end
  end

  setup do
    create_list(:model, 2)
  end

  test "GET /filters/models/focus offers every key of the vocabulary, labelled" do
    assert_api_response :get, 200 do
      assert_equal ::Model::FOCI, parsed_body.map { |row| row["value"] }
      assert_equal "Light Fighter", parsed_body.first["label"]
    end
  end

  test "GET /filters/models/focus filters by classification" do
    create(:model, classification: "combat", foci: %w[heavy_fighter])
    create(:model, classification: "industrial", foci: %w[mining])

    assert_api_response :get, 200, params: {classification: "combat"} do
      values = parsed_body.map { |row| row["value"] }

      assert_equal %w[heavy_fighter fighter], values
    end
  end
end
