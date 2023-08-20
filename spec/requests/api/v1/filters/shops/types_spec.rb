# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/filters/shops", type: :request, swagger_doc: "v1/schema.yaml" do
  path "/filters/shops/types" do
    get("Shop types") do
      operationId "shopTypes"
      tags "ShopFilters"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/FilterOption"}

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
