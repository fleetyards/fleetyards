# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/vehicles", type: :request, swagger_doc: "v1/schema.yaml" do
  before do
    host! "api.fleetyards.test"
  end

  path "/vehicles/{id}" do
    parameter name: "id", in: :path, description: "id", schema: {type: :string, format: :uuid}

    delete("delete vehicle") do
      operationId "destroy"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        let(:id) { SecureRandom.uuid }

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
