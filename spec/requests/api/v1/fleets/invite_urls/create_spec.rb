# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/fleets/invite_urls", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:member) { create(:user) }
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, members: [member], admins: [admin]) }
  let(:user) { admin }
  let(:fleetSlug) { fleet.slug }
  let(:request_body) do
    {
      expiresAfterMinutes: 60
    }
  end

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: admin.id,
      scopes: ["fleet", "fleet:write"]
    )
  end
  let(:wrong_scope_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: admin.id,
      scopes: ["public"]
    )
  end

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{fleetSlug}/invite-urls" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    post("Create Fleet Invite Url") do
      operationId "createFleetInviteUrl"
      tags "FleetInviteUrls"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/FleetInviteUrlCreateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/FleetInviteUrl"

        before do
          travel_to Time.utc(2305, 6, 13, 12, 0, 0)
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["expiresAfter"]).to eq("2305-06-13T13:00:00Z")
        end
      end

      include_examples "oauth_auth", success_status: 201

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:request_body) do
          {
            limit: -100
          }
        end

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:fleetSlug) { "unknown-fleet" }

        run_test!
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { member }

        run_test!
      end
    end
  end
end
