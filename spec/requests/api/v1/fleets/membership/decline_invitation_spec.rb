# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/fleets/membership", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:member) { create(:user) }
  let(:another_member) { create(:user) }
  let(:user) { member }
  let(:fleet) { create(:fleet, members: [another_member]) }
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

    create(:fleet_membership, :invited, fleet:, user: member)
  end

  path "/fleets/{fleetSlug}/membership/decline" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    put("Decline Membership") do
      operationId "declineFleetMembership"
      tags "FleetMembership"
      consumes "application/json"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: []},
        {OpenId: []}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"

        run_test!
      end

      response(200, "successful with OAuth token") do
        let(:user) { nil }
        let(:Authorization) { "Bearer #{oauth_access_token.token}" }

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:user) { another_member }

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:fleetSlug) { "unknown-fleet" }

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { create(:user) }

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
