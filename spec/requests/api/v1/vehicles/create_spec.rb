# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/vehicles", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:user) { users :data }
  let(:data) do
    {
      modelId: models(:andromeda).id
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/vehicles" do
    post("Create new Vehicle") do
      operationId "createVehicle"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      parameter name: :data, in: :body, schema: {"$ref": "#/components/schemas/VehicleCreateInput"}, required: true

      response(201, "successful") do
        schema "$ref": "#/components/schemas/Vehicle"

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }

        run_test!
      end
    end
  end
end
