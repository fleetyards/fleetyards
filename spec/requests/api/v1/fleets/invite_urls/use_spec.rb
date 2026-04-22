# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/fleets/invite_urls", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:member) { create(:user) }
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, members: [member], admins: [admin]) }
  let(:author) { create(:user) }
  let(:user) { author }
  let(:invite_url) { create(:fleet_invite_url, fleet: fleet, user: admin) }
  let(:request_body) do
    {
      token: invite_url.token
    }
  end

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["public"]
    )
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

      request_body required: true, schema: {"$ref": "#/components/schemas/FleetMembershipCreateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: []},
        {OpenId: []}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/FleetMember"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["username"]).to eq(user.username)
          expect(data["status"]).to eq("requested")

          notification = Notification.find_by(user: admin, notification_type: "fleet_member_requested")
          expect(notification).to be_present
          expect(notification.record).to be_a(FleetMembership)
        end
      end

      response(201, "successful with OAuth token") do
        let(:user) { nil }
        let(:Authorization) { "Bearer #{oauth_access_token.token}" }

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:request_body) do
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
