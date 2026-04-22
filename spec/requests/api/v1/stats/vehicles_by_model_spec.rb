# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/stats", type: :openapi, openapi_schema_name: :"v1/schema" do
  path "/stats/vehicles-by-model" do
    get("Stats Vehicles by Model") do
      operationId "vehiclesByModel"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref" => "#/components/schemas/BarChartStats"}

        run_test!
      end
    end
  end
end
