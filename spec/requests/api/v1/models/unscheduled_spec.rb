# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/models", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  path "/models/unscheduled" do
    get("Unscheduled Models") do
      operationId "modelsUnschduled"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
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
