# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/images", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :images

  path "/images" do
    get("Images list") do
      operationId "list"
      tags "Images"
      produces "application/json"

      parameter name: "page", in: :query, type: :number, required: false, default: 1
      parameter name: "perPage", in: :query, type: :string, required: false,
        default: Image.default_per_page
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ImageQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/ImageComplete"}

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
        schema type: :array,
          items: {"$ref": "#/components/schemas/ImageComplete"}

        let(:q) do
          {
            "modelIn" => ["andromeda"]
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(1)
        end
      end

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/ImageComplete"}

        let(:perPage) { 1 }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(1)
        end
      end
    end
  end

  path "/images/random" do
    get("Images random list") do
      operationId "random"
      description "Get a randomized List of 14 Images"
      tags "Images"
      produces "application/json"

      parameter name: "limit", in: :query, type: :number, required: false,
        minimum: 1, maximum: Image.default_per_page, default: 14

      response(200, "successful") do
        schema type: :array,
          items: {"$ref" => "#/components/schemas/ImageComplete"}

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(2)
        end
      end

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/ImageComplete"}

        let(:limit) { 1 }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(1)
        end
      end
    end
  end
end
