# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/filters/components", type: :request, swagger_doc: "v1/schema.yaml" do
  path "/filters/components/item-types" do
    get("Components Item Types Filters") do
      operationId "componentItemTypesFilters"
      tags "ComponentsFilters"
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
