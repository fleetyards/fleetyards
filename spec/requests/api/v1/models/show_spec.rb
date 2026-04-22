# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/models", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:model) { create(:model, :with_description, :with_store_image, :with_fleetchart_image) }
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
