# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/manufacturers", type: :request, swagger_doc: "v1/schema.yaml" do
  let!(:manufacturers) { create_list(:manufacturer, 2) }
  let!(:manufacturers_with_models) { create_list(:manufacturer, 5, :with_models) }

  path "/manufacturers" do
    get("Manufacturers list") do
      operationId "manufacturers"
      tags "Manufacturers"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: Manufacturer.default_per_page}, required: false
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

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to be > 0
          expect(items.count).to eq(7)
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

          expect(items.count).to eq(5)
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

  path "/manufacturers/with-models" do
    get("with_models manufacturer") do
      tags "Manufacturers"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Manufacturers"

        run_test!
      end
    end
  end
end
