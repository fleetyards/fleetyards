# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/vehicles", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:serial) { "DO-5920-FL" }
  let(:serial_other) { "DO-5921-FL" }
  let(:vehicle) { create(:vehicle, serial:, user: author) }
  let(:vehicle_other) { create(:vehicle, serial: serial_other) }

  before do
    sign_in(user) if user.present?

    vehicle
    vehicle_other
  end

  path "/vehicles/check-serial" do
    post("Check Vehicle Serial") do
      operationId "checkSerialVehicle"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/CheckInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Check"

        let(:input) do
          {
            value: serial
          }
        end

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body["taken"]).to eq(true)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Check"

        let(:input) do
          {
            value: "00-0000-00"
          }
        end

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body["taken"]).to eq(false)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Check"

        let(:input) do
          {
            value: serial_other
          }
        end

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body["taken"]).to eq(false)
        end
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:input) { nil }
        let(:user) { nil }

        run_test!
      end
    end
  end
end
