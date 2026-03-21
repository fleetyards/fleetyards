# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:invites) { create_list(:fleet_membership, 2, user: author, aasm_state: :invited) }

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

    invites
  end

  path "/fleets/invites" do
    get("Fleet Invites current User") do
      operationId "fleetInvites"
      tags "Fleets"
      produces "application/json"

      security [
        { SessionCookie: [] },
        { Oauth2: ["fleet", "fleet:read"] },
        { OpenId: ["fleet", "fleet:read"] }
      ]

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/FleetMember"}

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.size).to eq(2)
        end
      end

      response(200, "successful with OAuth token") do
        let(:user) { nil }
        let(:Authorization) { "Bearer #{oauth_access_token.token}" }

        run_test!
      end

      response(401, "unauthorized with wrong scope token") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }
        let(:Authorization) { "Bearer #{wrong_scope_access_token.token}" }

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
