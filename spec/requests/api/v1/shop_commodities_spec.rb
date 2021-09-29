# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/shop_commodities", type: :request, swagger_doc: "v1.yaml" do
  before do
    host! "api.fleetyards.test"
  end

  path "/stations/{station_slug}/shops/{shop_slug}/commodities" do
    parameter name: "station_slug", in: :path, type: :string, description: "station_slug"
    parameter name: "shop_slug", in: :path, type: :string, description: "shop_slug"

    get("list shop_commodities") do
      tags "ShopCommodities"
      produces "application/json"

      response(200, "successful") do
        let(:station_slug) { "123" }
        let(:shop_slug) { "123" }

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

  path "/shop-commodities/commodity-type-options" do
    get("commodity_item_types shop_commodity") do
      tags "ShopCommodities"
      produces "application/json"

      response(200, "successful") do
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

  path "/filters/shop-commodities/sub-categories" do
    get("sub_categories shop_commodity") do
      tags "ShopCommodities"
      produces "application/json"

      response(200, "successful") do
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
