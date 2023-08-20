# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1", type: :request, swagger_doc: "v1/schema.yaml" do
  path "/version" do
    get("Version of Fleetyards") do
      operationId "version"
      tags "Versions"
      produces "application/json"

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/Version"

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
