# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/stats", type: :openapi, openapi_schema_name: :"v1/schema" do
  path "/stats/models-by-size" do
    get("Stats Models by Size") do
      operationId "modelsBySize"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref" => "#/components/schemas/PieChartStats"}

        run_test!
      end
    end
  end
end
