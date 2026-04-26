# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/vehicles", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:vehicle) { create(:vehicle, user: author) }
  let(:other_vehicle) { create(:vehicle) }
  let(:id) { vehicle.id }

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

  path "/vehicles/{id}" do
    parameter name: "id", in: :path, description: "id", schema: {type: :string, format: :uuid}

    get("Show Vehicle") do
      operationId "showVehicle"
      tags "Vehicles"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Vehicle"

        run_test!
      end

      include_examples "oauth_auth"

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { SecureRandom.uuid }

        run_test!
      end

      response(404, "not found for other user") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { other_vehicle.id }

        run_test!
      end
    end
  end
end
