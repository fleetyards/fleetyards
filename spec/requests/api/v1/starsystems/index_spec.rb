# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/starsystems", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  path "/starsystems" do
    get("Starsystems list") do
      operationId "starsystems"
      tags "Starsystems"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: Starsystem.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/StarsystemQuery"
        },
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, type: :string, required: false

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/StarsystemMinimal"}

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
        schema type: :array, items: {"$ref": "#/components/schemas/StarsystemMinimal"}

        let(:q) do
          {
            "nameCont" => "Stanton"
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(1)
          expect(data.first["name"]).to eq("Stanton")
        end
      end

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/StarsystemMinimal"}

        let(:perPage) { 1 }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(1)
        end
      end
    end
  end
end
