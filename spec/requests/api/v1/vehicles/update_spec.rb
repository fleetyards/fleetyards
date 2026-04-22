# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/vehicles", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:vehicle) { create(:vehicle, user: author) }
  let(:other_vehicle) { create(:vehicle) }
  let(:id) { vehicle.id }
  let(:request_body) do
    {
      name: "Enterprise A"
    }
  end

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["hangar", "hangar:write"]
    )
  end
  let(:wrong_scope_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["public"]
    )
  end

  before do
    sign_in(user) if user.present?
  end

  path "/vehicles/{id}" do
    parameter name: "id", in: :path, description: "Vehicle id or serial", schema: {type: :string}

    put("Update Vehicle") do
      operationId "updateVehicle"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      request_body required: true, content: { "application/json" => { schema: {"$ref": "#/components/schemas/VehicleUpdateInput"} } }

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Vehicle"

        run_test!
      end

      response(200, "successful with boughtVia enum value") do
        schema "$ref": "#/components/schemas/Vehicle"

        let(:request_body) do
          {
            name: "Enterprise A",
            boughtVia: "pledge_store"
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["boughtVia"]).to eq("pledge_store")
        end
      end

      include_examples "oauth_auth"

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
    end
  end
end
