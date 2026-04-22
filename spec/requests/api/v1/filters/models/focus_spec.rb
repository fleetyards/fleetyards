# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/filters/models", type: :openapi, openapi_schema_name: :"v1/schema" do
  let!(:models) { create_list(:model, 2) }

  path "/filters/models/focus" do
    get("Model focus Filters") do
      operationId "modelFocusFilters"
      tags "ModelsFilters"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/FilterOption"}

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to be > 0
        end
      end
    end
  end
end
