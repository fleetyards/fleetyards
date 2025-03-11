# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/invite_urls", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:user) { nil }

  let(:inviteUrl) { fleet_invite_urls :starfleet_invite }

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

      let(:input) do
        {
          token: inviteUrl.token
        }
      end

      response(201, "successful") do
        schema "$ref": "#/components/schemas/FleetMember"

        let(:user) { users :troi }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["username"]).to eq("troi")
          expect(data["status"]).to eq("requested")
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { users :troi }
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

        let(:user) { users :data }

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end
    end
  end
end
