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

    put("Update Membership") do
      operationId "updateFleetMembership"
      tags "FleetMembership"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/FleetMembershipUpdateInput"}, required: true

      let(:input) do
        {
          primary: true
        }
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetMember"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["primary"]).to eq(true)
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:fleetSlug) { "unknown-fleet" }

        run_test!
      end

      response(404, "not found") do
        description "Fleet for this slug and user does not exist"
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { create(:user) }

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:input) do
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
