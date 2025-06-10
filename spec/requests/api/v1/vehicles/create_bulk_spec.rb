# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/vehicles", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user) }
  let(:user) { nil }
  let(:Authorization) { nil }
  let(:write_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["hangar:write"]
    )
  end
  let(:read_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["hangar:read"]
    )
  end
  let(:model) { create(:model) }
  let(:input) do
    {
      vehicles: [
        {
          modelId: model.id,
          wanted: true
        }
      ]
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/vehicles/bulk" do
    post("Create multiple vehicles") do
      operationId "createBulkVehicle"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/VehicleCreateBulkInput"}, required: true

      security [{
        SessionCookie: [],
        Oauth2: ["hangar", "hangar:write"]
      }]

      response(204, "successful") do
        let(:Authorization) { "Bearer #{write_access_token.token}" }

        run_test!
      end

      response(204, "successful") do
        let(:user) { author }

        run_test!
      end

      response(401, "unauthorized") do
        let(:Authorization) { "Bearer #{read_access_token.token}" }

        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end

      response(401, "unauthorized") do
        let(:Authorization) { "Bearer NOT_AUTHORIZED" }

        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end
    end
  end
end
