# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/models", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:model) { create(:model, :with_legacy_images) }
  let(:slug) { model.slug }

  path "/models/{slug}/store-image" do
    parameter name: "slug", in: :path, type: :string, description: "Model slug", required: true

    get("Model Storeimage") do
      operationId "modelStoreImage"
      deprecated true

      tags "Models"

      response(302, "successful") do
        run_test!
      end
    end
  end

  path "/models/{slug}/fleetchart-image" do
    parameter name: "slug", in: :path, type: :string, description: "Model slug", required: true

    get("Model Fleetchart Image") do
      operationId "modelFleetchartImage"
      deprecated true

      tags "Models"

      response(302, "successful") do
        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        produces "application/json"

        let(:slug) { "unknown-model" }

        run_test!
      end
    end
  end
end
