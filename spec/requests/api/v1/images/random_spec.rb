# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/images", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:images) { create_list(:image, 20) }

  before do
    images
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

          expect(data.count).to eq(14)
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
