# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/fleets/membership", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:member) { create(:user) }
  let(:user) { member }
  let(:fleet) { create(:fleet) }
  let(:fleetSlug) { fleet.slug }

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: member.id,
      scopes: ["public"]
    )
  end

  before do
    sign_in(user) if user.present?

    create(:fleet_membership, fleet:, user: member)
  end

  path "/fleets/{fleetSlug}/membership" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    put("Update Membership") do
      operationId "updateFleetMembership"
      tags "FleetMembership"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/FleetMembershipUpdateInput"}

      let(:request_body) do
        {
          primary: true
        }
      end

      security [
        {SessionCookie: []},
        {Oauth2: []},
        {OpenId: []}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetMember"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["primary"]).to eq(true)
        end
      end

      response(200, "successful with OAuth token", hidden: true) do
        let(:user) { nil }
        let(:Authorization) { "Bearer #{oauth_access_token.token}" }

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:fleetSlug) { "unknown-fleet" }

        run_test!
      end

      response(404, "not found", hidden: true) do
        description "Fleet for this slug and user does not exist"
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { create(:user) }

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:request_body) do
          {
            shipsFilter: "unknown"
          }
        end

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
