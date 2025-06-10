# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/models", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:model) { create(:model, :with_snub_crafts) }
  let(:slug) { model.slug }

  path "/models/{slug}/snub-crafts" do
    parameter name: "slug", in: :path, type: :string, description: "Model slug", required: true

    get("Model Snubcrafts") do
      operationId "modelSnubCrafts"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/Model"}

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(model.snub_crafts.count)
          expect(data.count).to be > 0
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:slug) { "unknown-model" }

        run_test!
      end
    end
  end
end
