# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/membership", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:fleet) { fleets :starfleet }

  let(:fleetSlug) { fleet.slug }
  let(:user) { users :data }

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{fleetSlug}/membership" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    get("Fleet Membership Detail") do
      operationId "fleetMembership"
      tags "FleetMembership"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetMember"

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["username"]).to eq("data")
        end
      end

      response(404, "not found") do
        description "Fleet for this slug and user does not exist"
        schema "$ref": "#/components/schemas/StandardError"

        let(:fleetSlug) { "unknown-fleet" }

        run_test!
      end

      response(404, "not found") do
        description "Membership for this slug and user does not exist"
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { users :worf }

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
