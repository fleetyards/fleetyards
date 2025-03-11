# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/members", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:user) { nil }

  let(:fleet) { fleets :starfleet }
  let(:fleetSlug) { fleet.slug }

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

      let(:input) do
        {
          username: "troi"
        }
      end

      response(201, "successful") do
        schema "$ref": "#/components/schemas/FleetMember"

        let(:user) { users :jeanluc }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["username"]).to eq("troi")
          expect(data["status"]).to eq("invited")
        end
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:user) { users :jeanluc }
        let(:input) do
          {
            username: "unknown"
          }
        end

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { users :jeanluc }
        let(:fleetSlug) { "unknown-fleet" }

        run_test!
      end

      response(403, "forbidden") do
        description "You are not the owner of this Fleet"
        schema "$ref": "#/components/schemas/StandardError"

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
