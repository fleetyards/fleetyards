# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/models", type: :request, swagger_doc: "v1/schema.yaml" do
  path "/models/updated" do
    get("Updated Models") do
      operationId "modelsUpdated"
      tags "Models"
      produces "application/json"

      parameter name: :from, in: :query, schema: {type: :string, format: :datetime}, required: false
      parameter name: :to, in: :query, schema: {type: :string, default: :now, format: :datetime}, required: false

      response(200, "successful") do
        let(:from) { 1.day.ago }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end

      response(304, "not modified") do
        run_test!
      end
    end
  end
end
