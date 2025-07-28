# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/members", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:another_member) { create(:user) }
  let(:user) { admin }
  let(:fleet) { create(:fleet, admins: [admin], members: [member, another_member]) }
  let(:fleetSlug) { fleet.slug }

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{fleetSlug}/members" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    get("Fleet Member List") do
      operationId "fleetMembers"
      tags "FleetMembers"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: FleetVehicle.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/FleetMemberQuery"
        },
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, type: :string, required: false

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/FleetMember"}

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to be > 0
          expect(data.count).to eq(3)
        end
      end

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/FleetMember"}

        let(:q) do
          {
            "usernameCont" => member.username
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(1)
          expect(data.first.dig("username")).to eq(member.username)
        end
      end

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/FleetMember"}

        let(:perPage) { 1 }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(1)
        end
      end

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/FleetMember"}

        let(:user) { member }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(3)
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:fleetSlug) { "unknown-fleet" }

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
