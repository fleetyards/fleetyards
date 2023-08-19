# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/filters/commodity_prices", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  path "/filters/commodity-prices/time-ranges" do
    get("Commodity Types") do
      operationId "commodityPriceTimeRanges"
      tags "CommodityPriceFilters"
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
