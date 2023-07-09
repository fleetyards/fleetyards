# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/shops", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  path "/shops" do
    get("Shops list") do
      operationId "list"
      tags "Shops"
      produces "application/json"

      parameter name: "page", in: :query, type: :number, required: false, default: 1
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
        schema "$ref": "#/components/schemas/Shops"

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to be > 0
          expect(items.count).to eq(5)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Shops"

        let(:q) do
          {
            "nameCont" => "Dumpers Depot"
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(1)
          expect(items.first["name"]).to eq("Dumpers Depot")
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Shops"

        let(:perPage) { 2 }

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(2)
        end
      end
    end
  end
end
