# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/vehicles", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:vehicle) { create(:vehicle, user: author)}
  let(:other_vehicle) { create(:vehicle)}
  let(:id) { vehicle.id }

  before do
    sign_in(user) if user.present?
  end

  path "/vehicles/{id}" do
    parameter name: "id", in: :path, description: "id", schema: {type: :string, format: :uuid}

    delete("Delete Vehicle") do
      operationId "destroyVehicle"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Vehicle"

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { SecureRandom.uuid }

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { other_vehicle.id }

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
