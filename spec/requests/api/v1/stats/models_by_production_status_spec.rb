# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/stats", type: :request, swagger_doc: "v1/schema.yaml" do
  path "/stats/models-by-production-status" do
    get("Stats Models by Production-Status") do
      operationId "modelsByProductionStatus"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref" => "#/components/schemas/PieChartStats"}

        run_test!
      end
    end
  end
end
