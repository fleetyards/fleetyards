# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/vehicles", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:admin) { create(:admin_user, resource_access: [:vehicles]) }
  let(:vehicle) { create(:vehicle, :with_name) }
  let(:id) { vehicle.id }
  let(:request_body) do
    {
      name: "Updated Vehicle"
    }
  end

  before do
    sign_in(admin) if admin.present?
  end

  path "/vehicles/{id}" do
    parameter name: "id", in: :path, description: "Vehicle id", schema: {type: :string, format: :uuid}

    put("Update Vehicle") do
      operationId "updateVehicle"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/VehicleInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Vehicle"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["name"]).to eq("Updated Vehicle")
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { SecureRandom.uuid }

        run_test!
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:admin) { create(:admin_user, resource_access: []) }

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:admin) { nil }

        run_test!
      end
    end
  end
end
