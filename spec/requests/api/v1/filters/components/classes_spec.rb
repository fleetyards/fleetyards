# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/filters/components", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  path "/filters/components/classes" do
    get("Commodity Types") do
      operationId "componentClasses"
      tags "ComponentFilters"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/FilterOption"}

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end
    end
  end
end
