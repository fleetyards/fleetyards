# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/membership", type: :request, swagger_doc: "v1/schema.yaml" do
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
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    delete("Leave Fleet") do
      operationId "leaveFleet"
      tags "FleetMembership"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: []},
        {OpenId: []}
      ]

      response(204, "successful") do
        run_test!
      end

      response(204, "successful with OAuth token") do
        let(:user) { nil }
        let(:Authorization) { "Bearer #{oauth_access_token.token}" }

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:fleetSlug) { "unknown-fleet" }

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
