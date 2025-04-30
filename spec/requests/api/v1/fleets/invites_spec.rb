# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:invites) { create_list(:fleet_membership, 2, user: author, aasm_state: :invited) }

  before do
    sign_in(user) if user.present?

    invites
  end

  path "/fleets/invites" do
    get("Fleet Invites current User") do
      operationId "fleetInvites"
      tags "Fleets"
      produces "application/json"

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/FleetMember"}

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.size).to eq(2)
        end
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }

        run_test!
      end
    end
  end
end
