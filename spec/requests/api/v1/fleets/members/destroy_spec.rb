# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/members", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:another_member) { create(:user) }
  let(:user) { admin }
  let(:fleet) { create(:fleet, admins: [admin], members: [member, another_member]) }
  let(:fleetSlug) { fleet.slug }
  let(:username) { member.username }

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

  path "/fleets/{fleetSlug}/members/{username}" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"
    parameter name: "username", in: :path, type: :string, description: "username"

    delete("Remove Fleet Member") do
      operationId "destroyFleetMember"
      tags "FleetMembers"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(204, "successful") do
        run_test!
      end

      response(204, "successful with OAuth token") do
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

      response(204, "successful") do
        description "Delete own membership if not admin"
        let(:user) { member }

        run_test!
      end

      response(404, "not found") do
        description "Fleet not found"
        schema "$ref": "#/components/schemas/StandardError"

        let(:fleetSlug) { "unknown-fleet" }

        run_test!
      end

      response(404, "not found") do
        description "Member not found"
        schema "$ref": "#/components/schemas/StandardError"

        let(:username) { "unknown-username" }

        run_test!
      end

      response(403, "forbidden") do
        description "Without enough permissions"
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { another_member }

        run_test!
      end

      response(403, "forbidden") do
        description "You are not the owner of this Fleet"
        schema "$ref": "#/components/schemas/StandardError"

        let(:username) { admin.username }

        run_test!
      end

      response(401, "unauthorized") do
        description "Without authentication"
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }

        run_test!
      end
    end
  end
end
