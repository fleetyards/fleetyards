# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/filters/models", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  path "/filters/models" do
    get("Models Filters") do
      operationId "modelFilters"
      tags "ModelsFilters"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/FilterOption"}

        run_test!
      end
    end
  end
end
