# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/manufacturers", type: :request, swagger_doc: "v1/schema.yaml" do
  path "/manufacturers/with-models" do
    get("Manufacturers list only with models.") do
      tags "Manufacturers"
      produces "application/json"
      deprecated true

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/ManufacturerMinimal"}

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
