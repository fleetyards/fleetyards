# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/models", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:model) { create(:model) }
  let(:slug) { model.slug }

  path "/models/{slug}" do
    parameter name: "slug", in: :path, type: :string, description: "Model slug", required: true

    get("Model Detail") do
      operationId "model"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelExtended"

        run_test!
      end

      response(404, "not found") do
        let(:slug) { "unknown-model" }

        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end
    end
  end
end
