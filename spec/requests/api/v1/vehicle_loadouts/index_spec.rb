# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/vehicle_loadouts", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:vehicle) { create(:vehicle, user: author) }
  let(:vehicle_id) { vehicle.id }

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["hangar", "hangar:read"]
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

    get("List Vehicle Loadouts") do
      operationId "vehicleLoadouts"
      tags "VehicleLoadouts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/VehicleLoadout"}

        before do
          create(:vehicle_loadout, vehicle: vehicle)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.count).to eq(1)
        end
      end

      include_examples "oauth_auth"

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:vehicle_id) { SecureRandom.uuid }

        run_test!
      end
    end
  end
end
