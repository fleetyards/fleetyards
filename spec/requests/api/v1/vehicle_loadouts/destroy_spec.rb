# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/vehicle_loadouts", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:vehicle) { create(:vehicle, user: author) }
  let(:vehicle_id) { vehicle.id }
  let(:vehicle_loadout) { create(:vehicle_loadout, vehicle: vehicle) }
  let(:id) { vehicle_loadout.id }

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

  path "/vehicles/{vehicle_id}/loadouts/{id}" do
    parameter name: "vehicle_id", in: :path, description: "Vehicle id", schema: {type: :string, format: :uuid}
    parameter name: "id", in: :path, description: "Loadout id", schema: {type: :string, format: :uuid}

    delete("Delete Vehicle Loadout") do
      operationId "destroyVehicleLoadout"
      tags "VehicleLoadouts"
      consumes "application/json"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/VehicleLoadout"

        run_test!
      end

      include_examples "oauth_auth"

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { SecureRandom.uuid }

        run_test!
      end
    end
  end
end
