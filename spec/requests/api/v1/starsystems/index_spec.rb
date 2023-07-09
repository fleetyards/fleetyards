# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/starsystems", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  path "/starsystems" do
    get("Starsystems list") do
      operationId "list"
      tags "Starsystems"
      produces "application/json"

      parameter name: "page", in: :query, type: :number, required: false, default: 1
      parameter name: "perPage", in: :query, type: :string, required: false,
        default: Starsystem.default_per_page
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
        schema "$ref": "#/components/schemas/Starsystems"

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
          expect(items.count).to eq(2)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Starsystems"

        let(:q) do
          {
            "nameCont" => "Stanton"
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(1)
          expect(items.first["name"]).to eq("Stanton")
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Starsystems"

        let(:perPage) { 1 }

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(1)
        end
      end
    end
  end
end
