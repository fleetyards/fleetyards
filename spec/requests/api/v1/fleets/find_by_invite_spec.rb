# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/fleets", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:fleet) { create(:fleet) }
  let(:fleet_invite_url) { create(:fleet_invite_url, fleet:) }
  let(:token) { fleet_invite_url.token }

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["fleet", "fleet:read"]
    )
  end
  let(:wrong_scope_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["public"]
    )
  end

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/find-by-invite/{token}" do
    parameter name: "token", in: :path, schema: { type: :string }, description: "Fleet Invite Token"

    post("Find Fleet by Invite") do
      operationId "findFleetByInvite"
      tags "Fleets"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Fleet"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["id"]).to eq(fleet.id)
        end
      end

      include_examples "oauth_auth"
    end
  end
end
