# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/membership", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:member) { create(:user) }
  let(:another_member) { create(:user) }
  let(:user) { member }
  let(:fleet) { create(:fleet, members: [another_member]) }
  let(:fleetSlug) { fleet.slug }

  before do
    sign_in(user) if user.present?

    create(:fleet_membership, :invited, fleet:, user: member)
  end

  path "/fleets/{fleetSlug}/membership/accept" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    put("Accept Membership") do
      operationId "acceptFleetMembership"
      tags "FleetMembership"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"

        run_test! do
          expect(member.fleets.reload.include?(fleet)).to be_truthy
        end
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
