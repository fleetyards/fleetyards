# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/fleets/membership", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:member) { create(:user, :with_rsi_handle, :with_avatar) }
  let(:user) { member }
  let(:fleet) { create(:fleet, :with_description) }
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

    get("Fleet Membership Detail") do
      operationId "fleetMembership"
      tags "FleetMembership"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: []},
        {OpenId: []}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetMember"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["username"]).to eq(member.username)
        end
      end

      response(200, "successful with OAuth token") do
        let(:user) { nil }
        let(:Authorization) { "Bearer #{oauth_access_token.token}" }

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        context "invalid fleet slug" do
          let(:fleetSlug) { "unknown-fleet" }

          run_test!
        end

        context "user without membership" do
          let(:user) { create(:user) }

          run_test!
        end
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }

        run_test!
      end
    end
  end
end
