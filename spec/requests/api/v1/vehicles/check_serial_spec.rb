# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/vehicles", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:user) { nil }

  before do
    host! "api.fleetyards.test"

    sign_in(user) if user.present?
  end

  path "/vehicles/check-serial" do
    post("check_serial vehicle") do
      operationId "checkSerial"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      parameter name: :data, in: :body, schema: {"$ref": "#/components/schemas/VehicleCheckSerialInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/VehicleCheckSerialResponse"

        let(:user) { users :data }
        let(:data) do
          {
            serial: "1234567890"
          }
        end

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

        let(:data) { nil }

        run_test!
      end
    end
  end
end
