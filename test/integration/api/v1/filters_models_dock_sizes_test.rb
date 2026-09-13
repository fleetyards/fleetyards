# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FiltersModelsDockSizesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/filters/models/dock-sizes" do
    get("Model Dock Sizes Filters") do
      operationId "modelDockSizesFilters"
      tags "ModelsFilters"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::FilterOptionsList
      end
    end
  end

  # The values have to be the enum names. A count-only assertion let the option
  # list drift to the integers behind them, which matched no model's dock_size
  # and left the admin select reading "No Option selected" on every ship.
  test "GET /filters/models/dock-sizes returns the enum names as values" do
    assert_api_response :get, 200 do
      values = parsed_body.map { |filter| filter["value"] }

      assert_equal Model.dock_sizes.keys, values
    end
  end
end
