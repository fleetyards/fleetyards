# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/members", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:new_member) { create(:user) }
  let(:user) { admin }
  let(:fleet) { create(:fleet, admins: [admin], members: [member]) }
  let(:fleetSlug) { fleet.slug }
  let(:input) do
    {
      username: new_member.username
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{fleetSlug}/members" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    post("Create Member") do
      operationId "createFleetMember"
      tags "FleetMembers"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/FleetMemberCreateInput"}, required: true

      response(201, "successful") do
        schema "$ref": "#/components/schemas/FleetMember"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["username"]).to eq(new_member.username)
          expect(data["status"]).to eq("invited")
        end
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:input) do
          {
            username: "unknown"
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

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }

        run_test!
      end
    end
  end
end
