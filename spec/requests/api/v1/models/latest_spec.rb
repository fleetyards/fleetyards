# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/models", type: :openapi, openapi_schema_name: :"v1/schema" do
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
