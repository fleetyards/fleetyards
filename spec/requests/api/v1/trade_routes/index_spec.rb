# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/trade_routes", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  path "/trade-routes" do
    get("Trade Routes") do
      operationId "tradeRoutes"
      tags "TradeRoutes"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: TradeRoute.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/TradeRouteQuery"
        },
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, type: :string, required: false

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/TradeRoute"}

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to be > 0
          expect(data.count).to eq(3)
        end
      end

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/TradeRoute"}

        let(:q) do
          {
            "destinationStationIn" => ["port-olisar"]
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(1)
          expect(data.first.dig("destination", "name")).to eq("Port Olisar")
        end
      end

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/TradeRoute"}

        let(:perPage) { 2 }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(2)
        end
      end
    end
  end
end
