# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/filters/shop_commodities", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  path "/filters/shop-commodities/commodity-type-options" do
    get("Shop Commodity Commodity Type Options") do
      operationId "commodityTypeOptions"
      tags "ShopCommodityFilters"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/CommodityItemType"}

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
