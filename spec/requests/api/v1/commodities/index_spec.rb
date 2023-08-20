# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/commodities", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  path "/commodities" do
    get("Commodities list") do
      operationId "commodities"
      tags "Commodities"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: Commodity.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/CommodityQuery"
        },
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, type: :string, required: false

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/Commodity"}

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
          expect(data.count).to eq(2)
        end
      end

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/Commodity"}

        let(:q) do
          {
            "nameCont" => "Gold"
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(1)
          expect(data.first["name"]).to eq("Gold")
        end
      end

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/Commodity"}

        let(:perPage) { 2 }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(2)
        end
      end
    end
  end
end
