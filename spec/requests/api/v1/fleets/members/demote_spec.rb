# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/members", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:officer) { create(:user) }
  let(:another_member) { create(:user) }
  let(:user) { admin }
  let(:fleet) { create(:fleet, admins: [admin], officers: [officer], members: [member, another_member]) }
  let(:fleetSlug) { fleet.slug }
  let(:username) { officer.username }

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{fleetSlug}/members/{username}/demote" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"
    parameter name: "username", in: :path, type: :string, description: "Username"

    put("Demote Member") do
      operationId "demoteFleetMember"
      tags "FleetMembers"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetMember"

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:fleetSlug) { "unknown-fleet" }

        run_test!
      end

      response(404, "not found") do
        description "No Member found"
        schema "$ref": "#/components/schemas/StandardError"

        let(:username) { "unknown-username" }

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:username) { admin.username }

        run_test!
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { another_member }

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
