# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1", type: :request, swagger_doc: "v1/schema.yaml" do
  path "/sc-data/version" do
    get("SC Data Version") do
      operationId "scDataVersion"
      tags "Versions"
      produces "application/json"

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/ScDataVersion"

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
