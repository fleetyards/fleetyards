# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/hangar/stats", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:user) { nil }

  before do
    sign_in(user) if user.present?
  end

  path "/hangar/stats/models-by-classification" do
    get("Hangar Stats - Models by Classification") do
      operationId "hangarModelsByClassification"
      tags "HangarStats"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/PieChartStats"}

        let(:user) { users :data }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end
    end
  end
end
