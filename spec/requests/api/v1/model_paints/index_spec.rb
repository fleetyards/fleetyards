# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/model_paints", type: :openapi, openapi_schema_name: :"v1/schema" do
  let!(:model_paints) { create_list(:model_paint, 3) }

  path "/model-paints" do
    get("Model Paints List") do
      operationId "paints"
      tags "ModelPaints"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: ModelPaint.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ModelPaintQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/ModelPaint"}

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to be > 0
          expect(data.count).to eq(3)
        end
      end

      response(200, "successful", hidden: true) do
        schema type: :array,
          items: {"$ref": "#/components/schemas/ModelPaint"}

        let(:q) do
          {
            "modelSlugEq" => model_paints.first.model.slug
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(1)
          expect(data.first["name"]).to eq(model_paints.first.name)
        end
      end

      response(200, "successful", hidden: true) do
        schema type: :array,
          items: {"$ref": "#/components/schemas/ModelPaint"}

        let(:perPage) { 2 }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(2)
        end
      end
    end
  end
end
