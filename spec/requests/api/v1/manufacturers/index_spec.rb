# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/manufacturers", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :manufacturers

  path "/manufacturers" do
    get("Manufacturers list") do
      operationId "list"
      tags "Manufacturers"
      produces "application/json"

      parameter name: "page", in: :query, type: :number, required: false, default: 1
      parameter name: "perPage", in: :query, type: :string, required: false,
        default: Manufacturer.default_per_page
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ManufacturerQuery"
        },
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, type: :string, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Manufacturers"

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
          expect(items.count).to eq(3)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Manufacturers"

        let(:q) do
          {
            "withModels" => true
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(2)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Manufacturers"

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
