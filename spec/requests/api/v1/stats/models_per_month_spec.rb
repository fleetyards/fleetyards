# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/stats", type: :request, swagger_doc: "v1/schema.yaml" do
  path "/stats/models-per-month" do
    get("Stats Models per Month") do
      operationId "modelsPerMonth"
      tags "Stats"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref" => "#/components/schemas/PieChartStats"}

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end
    end
  end
end
