# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/vehicles", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:serial) { "DO-5920-FL" }
  let(:serial_other) { "DO-5921-FL" }
  let(:vehicle) { create(:vehicle, serial:, user: author) }
  let(:vehicle_other) { create(:vehicle, serial: serial_other) }

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

    vehicle
    vehicle_other
  end

  path "/vehicles/check-serial" do
    post("Check Vehicle Serial") do
      operationId "checkSerialVehicle"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/CheckInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Check"

        let(:request_body) do
          {
            value: serial
          }
        end

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body["taken"]).to eq(true)
        end
      end

      response(200, "successful with OAuth token", hidden: true) do
        let(:user) { nil }
        let(:Authorization) { "Bearer #{oauth_access_token.token}" }
        let(:request_body) { {value: serial} }

        run_test!
      end

      response(401, "unauthorized with wrong scope token") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }
        let(:Authorization) { "Bearer #{wrong_scope_access_token.token}" }
        let(:request_body) { {value: serial} }

        run_test!
      end

      response(200, "successful", hidden: true) do
        schema "$ref": "#/components/schemas/Check"

        let(:request_body) do
          {
            value: "00-0000-00"
          }
        end

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body["taken"]).to eq(false)
        end
      end

      response(200, "successful", hidden: true) do
        schema "$ref": "#/components/schemas/Check"

        let(:request_body) do
          {
            value: serial_other
          }
        end

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body["taken"]).to eq(false)
        end
      end

      response(401, "unauthorized", hidden: true) do
        schema "$ref": "#/components/schemas/StandardError"

        let(:request_body) do
          {
            value: "foo"
          }
        end
        let(:user) { nil }

        run_test!
      end
    end
  end
end
