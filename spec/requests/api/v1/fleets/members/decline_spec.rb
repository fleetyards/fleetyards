# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/members", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:user) { users :jeanluc }

  let(:fleet) { fleets :starfleet }
  let(:fleetSlug) { fleet.slug }

  let(:member) { users :will }
  let(:username) { member.username }

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{fleetSlug}/members/{username}/decline" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"
    parameter name: "username", in: :path, type: :string, description: "Username"

    put("Decline Member") do
      operationId "declineFleetMember"
      tags "FleetMembers"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:member) { users :data }

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

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { users :data }

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
