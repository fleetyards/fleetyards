# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/components", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  path "/components/class_filters" do
    get("Commodity Types") do
      deprecated true
      operationId "DEPRECATEDcomponentClasses"
      tags "Components"
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

  path "/components/item_type_filters" do
    get("Commodity Types") do
      deprecated true
      operationId "DEPRECATEDcomponentItemTypes"
      tags "Components"
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
