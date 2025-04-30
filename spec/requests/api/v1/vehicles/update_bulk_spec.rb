# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/vehicles", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:vehicles) { create_list(:vehicle, 3, user: author) }
  let(:input) do
    {
      ids: vehicles.pluck(:id),
      wanted: true
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/vehicles/bulk" do
    put("Update multiple vehicles") do
      operationId "updateBulkVehicle"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/VehicleUpdateBulkInput"}, required: true

      response(204, "successful") do
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
