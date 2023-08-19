# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/commodity_prices", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:user) { nil }

  let(:commodity) { commodities :gold }
  let(:shop) { shops :dumpers }

  before do
    sign_in(user) if user.present?
  end

  path "/commodity-prices" do
    post("Create Commodity Price") do
      operationId "createPrice"
      tags "CommodityPrices"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/CommodityPriceInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/CommodityPrice"

        let(:user) { users :data }
        let(:input) do
          {
            shopCommodityId: commodity.id,
            shopCommodityType: "commodity",
            shopId: shop.id,
            price: "100"
          }
        end

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["price"]).to eq(100.0)
        end
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:user) { users :data }
        let(:input) { nil }

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:input) { nil }

        run_test!
      end
    end
  end
end
