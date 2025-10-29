# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/images", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:images) { create_list(:image, 5) }

  before do
    images
  end

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
        schema "$ref": "#/components/schemas/Images"

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to be > 0
          expect(items.count).to eq(5)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Images"

        let(:q) do
          {
            "modelIn" => [images.first.gallery.slug]
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(1)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Images"

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
