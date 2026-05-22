# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/stats", type: :openapi, openapi_schema_name: :"v1/schema" do
  path "/stats/vehicles-per-month" do
    get("Stats Vehicles per Month") do
      operationId "vehiclesPerMonth"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref" => "#/components/schemas/BarChartStats"}

        run_test!
      end
    end
  end
end
