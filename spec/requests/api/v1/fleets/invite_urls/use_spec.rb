# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/invite_urls", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:member) { create(:user) }
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, members: [member], admins: [admin]) }
  let(:user) { create(:user) }
  let(:invite_url) { create(:fleet_invite_url, fleet: fleet, user: admin) }
  let(:input) do
    {
      token: invite_url.token
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/use-invite" do
    post("Create Fleet Membership by Invite") do
      operationId "useFleetInvite"
      tags "FleetInviteUrls"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/FleetMembershipCreateInput"}, required: true

      response(201, "successful") do
        schema "$ref": "#/components/schemas/FleetMember"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["username"]).to eq(user.username)
          expect(data["status"]).to eq("requested")
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:input) do
          {
            token: "unknown"
          }
        end

        run_test!
      end

      response(400, "bad request") do
        description "User is already a member of this fleet"
        schema "$ref": "#/components/schemas/ValidationError"

        let(:user) { member }

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
