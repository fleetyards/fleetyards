# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/vehicle_loadouts", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:vehicle) { create(:vehicle, user: author) }
  let(:vehicle_id) { vehicle.id }
  let(:input) do
    {
      name: "PvE Setup"
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

  path "/vehicles/{vehicle_id}/loadouts" do
    parameter name: "vehicle_id", in: :path, description: "Vehicle id or serial", schema: {type: :string}

    post("Create Vehicle Loadout") do
      operationId "createVehicleLoadout"
      tags "VehicleLoadouts"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/VehicleLoadoutInput"}, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/VehicleLoadout"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["name"]).to eq("PvE Setup")
        end
      end

      response(201, "successful with from_defaults") do
        schema "$ref": "#/components/schemas/VehicleLoadout"

        let(:input) do
          {
            name: "Default Loadout",
            fromDefaults: true
          }
        end

        run_test!
      end

      include_examples "oauth_auth", success_status: 201

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:vehicle_id) { SecureRandom.uuid }

        run_test!
      end
    end
  end
end
