# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/images", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :images

  path "/images" do
    get("Images list") do
      operationId "images"
      tags "Images"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {
        type: :string, default: Image.default_per_page
      }, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ImageQuery"
        },
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, type: :string, required: false

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/Image"}

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
          items: {"$ref": "#/components/schemas/Image"}

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
          items: {"$ref": "#/components/schemas/Image"}

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
      operationId "imagesRandom"
      description "Get a randomized List of 14 Images"
      tags "Images"
      produces "application/json"

      parameter name: "limit", in: :query, schema: {
        type: :number,
        minimum: 1,
        maximum: Image.default_per_page,
        default: 14
      }, required: false

      response(200, "successful") do
        schema type: :array,
          items: {"$ref" => "#/components/schemas/Image"}

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(2)
        end
      end

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/Image"}

        let(:limit) { 1 }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(1)
        end
      end
    end
  end
end
