# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/models", type: :request, swagger_doc: "v1/schema.yaml" do
  path "/models/latest" do
    get("Latest Models") do
      operationId "modelsLatest"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/Model"}

        run_test!
      end
    end
  end
end
