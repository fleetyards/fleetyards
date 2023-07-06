# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/vehicles", type: :request, swagger_doc: "v1/schema.yaml" do
  before do
    host! "api.fleetyards.test"
  end

  path "/vehicles/bulk" do
    put("update_bulk vehicle") do
      operationId "updateBulk"
      tags "Vehicles"
      consumes "application/json"
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

  path "/vehicles/destroy-bulk" do
    put("destroy_bulk vehicle") do
      operationId "destroyBulk"
      tags "Vehicles"
      consumes "application/json"
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
