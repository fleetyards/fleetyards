# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/shops", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  path "/shops" do
    get("Shops list") do
      operationId "list"
      tags "Shops"
      produces "application/json"

      parameter name: "page", in: :query, type: :string, required: false, default: "1"
      parameter name: "perPage", in: :query, type: :string, required: false,
        default: Shop.default_per_page
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ShopQuery"
        },
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, type: :string, required: false

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/ShopMinimal"}

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
          expect(data.count).to eq(5)
        end
      end

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/ShopMinimal"}

        let(:q) do
          {
            "nameCont" => "Dumpers Depot"
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(1)
          expect(data.first["name"]).to eq("Dumpers Depot")
        end
      end

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/ShopMinimal"}

        let(:perPage) { 2 }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(2)
        end
      end
    end
  end
end
