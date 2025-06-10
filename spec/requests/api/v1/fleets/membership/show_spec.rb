# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/membership", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:member) { create(:user) }
  let(:user) { member }
  let(:fleet) { create(:fleet) }
  let(:fleetSlug) { fleet.slug }

  before do
    sign_in(user) if user.present?

    create(:fleet_membership, fleet:, user: member)
  end

  path "/fleets/{fleetSlug}/membership" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    get("Fleet Membership Detail") do
      operationId "fleetMembership"
      tags "FleetMembership"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetMember"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["username"]).to eq(member.username)
        end
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
