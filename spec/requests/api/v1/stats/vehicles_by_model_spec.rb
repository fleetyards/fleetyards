# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/stats", type: :request, swagger_doc: "v1/schema.yaml" do
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
