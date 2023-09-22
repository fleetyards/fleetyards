# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/membership", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:user) { nil }

  let(:fleet) { fleets :starfleet }
  let(:fleetSlug) { fleet.slug }

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{fleetSlug}/membership/accept" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    put("Accept Membership") do
      operationId "acceptMembership"
      tags "FleetMembership"
      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"

        let(:user) { users :will }

        run_test! do
          expect(user.fleets.reload.include?(fleet)).to be_truthy
        end
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:user) { users :jeanluc }

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { users :will }
        let(:fleetSlug) { "unknown-fleet" }

        run_test!
      end

      response(404, "not found") do
        description "No Membership found"
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { users :worf }

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end
    end
  end
end
