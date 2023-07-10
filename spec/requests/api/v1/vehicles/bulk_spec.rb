# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/vehicles", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:user) { nil }

  before do
    sign_in(user) if user.present?
  end

  path "/vehicles/bulk" do
    put("Update multiple vehicles") do
      operationId "vehicleUpdateBulk"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      parameter name: :data, in: :body, schema: {"$ref": "#/components/schemas/VehicleBulkUpdateInput"}, required: true

      response(204, "successful") do
        let(:user) { users :data }

        let(:data) do
          {
            ids: [vehicles(:enterprise).id],
            wanted: true
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

  path "/vehicles/destroy-bulk" do
    put("Destroy multiple Vehicles") do
      operationId "vehicleDestroyBulk"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      parameter name: :data, in: :body, schema: {"$ref": "#/components/schemas/VehicleBulkDestroyInput"}, required: true

      response(204, "successful") do
        let(:user) { users :data }
        let(:data) do
          {
            ids: [vehicles(:enterprise).id]
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
